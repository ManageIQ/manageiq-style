module ManageIQ
module Style
module Linter
  class Base
    attr_reader :branch_options, :files_from_cli, :logger, :options

    OUTPUT_FORMAT          = "%<path>s:%<line>d:%<column>d: %<message>s\n".freeze
    DEFAULT_BRANCH_OPTIONS = {
      :pull_request => true,
      :merge_target => "master",
    }.freeze


    def initialize(files_from_cli, options = {})
      require 'logger'

      branch_option_args            = options.delete(:branch_options) { |_| {} }
      @branch_options               = DEFAULT_BRANCH_OPTIONS.dup.merge(branch_option_args)
      @branch_options[:repo_path] ||= Dir.pwd
      @branch_options[:repo_name] ||= File.basename(@branch_options[:repo_path])

      @options                      = options
      @options[:output]             = :stdout # :stdout or :logger
      @options[:logger_io]          = STDOUT if @options[:debug]

      @files_from_cli               = files_from_cli || []

      set_logger
    end

    def run
      logger.info("#{log_header} Starting run...")
      if files_to_lint.empty?
        logger.info("#{log_header} Skipping run due to no candidate files.")
        return
      end

      require 'tempfile'
      result = Dir.mktmpdir do |dir|
        files = collected_config_files(dir)
        if files.blank?
          logger.error("#{log_header} Failed to run due to missing config files.")
          return failed_linter_offenses("missing config files")
        else
          files += collected_files_to_lint(dir)
          logger.info("#{log_header} Collected #{files.length} files.")
          logger.debug { "#{log_header} File list: #{files.inspect}"}
          run_linter(dir)
        end
      end

      offenses = parse_output(result.output)
      logger.info("#{log_header} Completed run with #{offenses.fetch_path('summary', 'offense_count')} offenses")
      output_offenses offenses
      offenses
    end

    private

    def output_offenses(offenses_json)
      case options[:output]
      when :stdout
        offenses_json["files"].each do |file|
          file["offenses"].each do |offense|
            message = "#{offense["severity"]}: #{offense["cop_name"]}: #{offense["message"]}"
            STDOUT.printf(OUTPUT_FORMAT, :path    => file["path"],
                                         :line    => offense["location"]["line"],
                                         :column  => offense["location"]["column"],
                                         :message => message)
          end
        end
      when :logger
        logger.debug { "#{log_header} Offenses: #{offenses.inspect}" }
      end
    end

    def parse_output(output)
      JSON.parse(output.chomp)
    rescue JSON::ParserError => error
      logger.error("#{log_header} #{error.message}")
      logger.error("#{log_header} Failed to parse JSON result #{output.inspect}")
      return failed_linter_offenses("error parsing JSON result")
    end

    def collected_config_files(dir)
      config_files.select { |path| extract_file(path, dir, branch_service.pull_request?) }
    end

    def collected_files_to_lint(dir)
      files_to_lint.select { |path| extract_file(path, dir) }
    end

    def extract_file(path, destination_dir, merged = false)
      content = branch_service.content_at(path, merged)
      return false unless content

      perm      = branch_service.permission_for(path, merged)
      temp_file = File.join(destination_dir, path)
      FileUtils.mkdir_p(File.dirname(temp_file))

      # Use "wb" to prevent Encoding::UndefinedConversionError: "\xD0" from
      # ASCII-8BIT to UTF-8
      File.write(temp_file, content, :mode => "wb", :perm => perm)

      true
    end

    def branch_service
      @branch_service ||= GitService::Branch.new(branch_options)
    end

    def diff_service
      @diff_service ||= branch_service.diff
    end

    def files_to_lint
      @files_to_lint ||= begin
        unfiltered_files  = branch_service.pull_request? ? diff_service.new_files : branch_service.tip_files
        unfiltered_files &= files_from_cli unless files_from_cli.empty?
        # puts "unfiltered_files & files_from_cli  = #{unfiltered_files & files_from_cli}"
        # puts "files_from_cli & unfiltered_files  = #{files_from_cli & unfiltered_files}"
        filtered_files(unfiltered_files)
      end
    end

    def run_linter(dir)
      logger.info("#{log_header} Executing linter...")
      require 'awesome_spawn'
      result = AwesomeSpawn.run(linter_executable, :params => linter_cli_options, :chdir => dir)
      handle_linter_output(result)
    end

    def handle_linter_output(result)
      # rubocop exits 1 both when there are errors and when there are style issues.
      #   Instead of relying on just exit_status, we check if there is anything on stderr.
      return result if result.exit_status.zero? || result.error.blank?
      FailedLinterRun.new(failed_linter_offenses("#{self.class.name} STDERR:\n```\n#{result.error}\n```"))
    end

    def failed_linter_offenses(message)
      {
        "files" => [
          {
            "path"     => "\\*\\*",
            "offenses" => [
              {
                "severity" => "fatal",
                "message"  => message,
                "cop_name" => self.class.name.titleize
              }
            ]
          }
        ],
        "summary" => {
          "offense_count"        => 1,
          "target_file_count"    => files_to_lint.length,
          "inspected_file_count" => files_to_lint.length
        }
      }
    end

    def log_header
      "#{self.class.name} Repo: #{@branch_options[:repo_name]} Branch #{branch_service.name} -"
    end

    class FailedLinterRun
      attr_reader :output
      def initialize(message)
        @output = message.to_json
      end
    end

    def set_logger
      logger_io = @options[:logfile] || File::NULL
      @logger   = Logger.new(logger_io)
    end
  end
end
end
end

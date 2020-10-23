module ManageIQ
  module Style
    class CLI
      def self.run
        new.run
      end

      def initialize(options = parse_cli_options)
        @opts = options
      end

      def parse_cli_options
        require 'optimist'

        Optimist.options do
          usage    "[OPTIONS]"
          synopsis "\nThe ManageIQ community's style configuration utility."
          version  "v#{ManageIQ::Style::VERSION}\n"

          opt :install, "Install or update the style configurations", :default => false, :required => true
        end
      end

      def run
        install if @opts[:install]
      end

      def install
        require 'yaml'
        require 'more_core_extensions/all'

        check_for_codeclimate_channel
        update_rubocop_yml
        write_rubocop_cc_yml
        ensure_rubocop_local_yml_exists
        update_codeclimate_yml
        update_generator
      end

      private

      def check_for_codeclimate_channel
        begin
          require 'open-uri'
          URI::HTTPS.build(
            :host => "raw.githubusercontent.com",
            :path => File.join("/codeclimate", "codeclimate-rubocop", "channel", cc_rubocop_channel, "Gemfile")
          ).open
        rescue OpenURI::HTTPError
          puts "RuboCop version #{rubocop_version.version} is not supported by CodeClimate."
          exit 1
        end
      end

      def update_rubocop_yml(file = ".rubocop.yml")
        data = begin
          YAML.load_file(file)
        rescue Errno::ENOENT
          {}
        end

        data.store_path("inherit_gem", "manageiq-style", ".rubocop_base.yml")
        data["inherit_from"] = [".rubocop_local.yml"]

        File.write(".rubocop.yml", data.to_yaml.sub("---\n", ""))
      end

      def write_rubocop_cc_yml(file = ".rubocop_cc.yml")
        data = {
          "inherit_from" => [
            ".rubocop_base.yml",
            ".rubocop_cc_base.yml",
            ".rubocop_local.yml"
          ]
        }

        File.write(file, data.to_yaml.sub("---\n", ""))
      end

      def ensure_rubocop_local_yml_exists(file = ".rubocop_local.yml")
        require 'fileutils'
        FileUtils.touch(file)
      end

      def update_codeclimate_yml(file = ".codeclimate.yml")
        data = begin
          YAML.load_file(file)
        rescue Errno::ENOENT
          {}
        end

        data["prepare"] = {
          "fetch" => [
            {"url" => "https://raw.githubusercontent.com/ManageIQ/manageiq-style/master/.rubocop_base.yml",    "path" => ".rubocop_base.yml"},
            {"url" => "https://raw.githubusercontent.com/ManageIQ/manageiq-style/master/.rubocop_cc_base.yml", "path" => ".rubocop_cc_base.yml"}
          ]
        }

        data.delete_path("engines", "rubocop")

        data["plugins"] ||= {}
        data["plugins"]["rubocop"] = {
          "enabled" => true,
          "config"  => ".rubocop_cc.yml",
          "channel" => cc_rubocop_channel,
        }

        File.write(".codeclimate.yml", data.to_yaml.sub("---\n", ""))
      end

      def update_generator
        plugin_dir = "lib/generators/manageiq/plugin/templates"

        return unless File.directory?(plugin_dir)

        update_rubocop_yml(File.join(plugin_dir, ".rubocop.yml"))
        write_rubocop_cc_yml(File.join(plugin_dir, ".rubocop_cc.yml"))
        ensure_rubocop_local_yml_exists(File.join(plugin_dir, ".rubocop_local.yml"))
        update_codeclimate_yml(File.join(plugin_dir, ".codeclimate.yml"))
      end

      def cc_rubocop_channel
        @cc_rubocop_channel ||= "rubocop-#{rubocop_version.segments[0]}-#{rubocop_version.segments[1]}"
      end

      def rubocop_version
        @rubocop_version ||= begin
          require 'rubocop'
          Gem::Version.new(RuboCop::Version.version)
        end
      end
    end
  end
end

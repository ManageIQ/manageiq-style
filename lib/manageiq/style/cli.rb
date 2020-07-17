require "manageiq/style"

module Manageiq
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
          usage    "manageiq-version [OPTIONS]"
          synopsis "The ManageIQ communities style configuration utility"
          version  "v#{Manageiq::Style::VERSION}\n"

          opt :install, "Install or update the style configurations", :default => false
        end
      end

      def run
        version if @opts[:version]
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

      def update_rubocop_yml
        data = begin
          YAML.load_file(".rubocop.yml")
        rescue Errno::ENOENT
          {}
        end

        data.store_path("inherit_gem", "manageiq-style", ".rubocop_base.yml")
        data["inherit_from"] = [".rubocop_local.yml"]

        File.write(".rubocop.yml", data.to_yaml)
      end

      def write_rubocop_cc_yml
        File.write(".rubocop_cc.yml", {
          "inherit_from" => [
            ".rubocop_base.yml",
            ".rubocop_cc_base.yml",
            ".rubocop_local.yml"
          ]
        }.to_yaml)
      end

      def ensure_rubocop_local_yml_exists
        File.write(".rubocop_local.yml", "\n") unless File.exists?(".rubocop_local.yml")
      end

      def update_codeclimate_yml
        data = begin
          YAML.load_file(".codeclimate.yml")
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

        File.write(".codeclimate.yml", data.to_yaml)
      end

      def update_generator
        require 'fileutils'
        plugin_dir = "lib/generators/manageiq/plugin/templates"

        return unless File.directory?(plugin_dir)

        [".codeclimate.yml", ".rubocop.yml", ".rubocop_cc.yml"].each do |source|
          FileUtils.cp(source, File.join(plugin_dir, source))
        end

        File.write(File.join(plugin_dir, ".rubocop_local.yml"), "\n")
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

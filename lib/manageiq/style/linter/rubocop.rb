require 'manageiq/style/linter/base'

require 'rubocop'

module ManageIQ
module Style
module Linter
  class Rubocop < Base
    CONFIG_FILES = %w[.rubocop.yml .rubocop_base.yml .rubocop_local.yml].freeze

    private

    def config_files
      CONFIG_FILES
    end

    def linter_executable
      'rubocop'
    end

    def linter_cli_options
      {:format => 'json', :no_display_cop_names => nil}
    end

    def filtered_files(files)
      files.select do |file|
        file.end_with?(".rb", ".ru", ".rake") || %w[Gemfile Rakefile].include?(File.basename(file))
      end.reject do |file|
        file.end_with?("db/schema.rb")
      end
    end
  end
end
end
end

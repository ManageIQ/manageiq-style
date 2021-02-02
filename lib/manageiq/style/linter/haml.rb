require 'manageiq/style/linter/base'

module ManageIQ
module Style
module Linter
  class Haml < Base
    private

    def config_files
      [".haml-lint.yml"] + Linter::Rubocop::CONFIG_FILES
    end

    def linter_executable
      'haml-lint *'
    end

    def linter_cli_options
      {:reporter => 'json'}
    end

    def filtered_files(files)
      files.select { |file| file.end_with?(".haml") }
    end
  end
end
end
end

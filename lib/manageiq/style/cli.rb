require 'fileutils'

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

        update_rubocop_yml
        ensure_rubocop_local_yml_exists
        ensure_haml_lint_yml
        update_yamllint

        update_generator
        update_gem_source
      end

      private

      def update_rubocop_yml(file = ".rubocop.yml")
        data = begin
          YAML.load_file(file)
        rescue Errno::ENOENT
          {}
        end

        data.store_path("inherit_gem", "manageiq-style", ".rubocop_base.yml")
        data["inherit_from"] = [".rubocop_local.yml"]

        File.write(file, data.to_yaml.sub("---\n", ""))
      end

      def ensure_rubocop_local_yml_exists(file = ".rubocop_local.yml")
        FileUtils.touch(file)
      end

      def ensure_haml_lint_yml(file = ".haml-lint.yml")
        return if File.exist?(file)

        FileUtils.ln_s(".rubocop.yml", file)
      end

      def update_yamllint(file = ".yamllint")
        data = begin
          YAML.load_file(file)
        rescue Errno::ENOENT
          {}
        end

        data["ignore"] ||= ""
        data["ignore"] << "/locale/**\n" unless data["ignore"].include?("/locale/**")
        data["ignore"] << "/vendor/**\n" unless data["ignore"].include?("/vendor/**")
        data["ignore"].chomp!

        data["extends"] = "relaxed"

        data.store_path("rules", "indentation", "indent-sequences", false)
        data.store_path("rules", "line-length", "max", 1000)

        File.write(file, data.to_yaml.sub("---\n", ""))
      end

      def update_gem_source
        if (gemspec = Dir.glob("*.gemspec").first)
          update_gemspec(gemspec)
        elsif File.exist?("Gemfile")
          update_gemfile
        end
      end

      def update_gemspec(gemspec)
        contents = File.read(gemspec)
        return if contents.include?("manageiq-style")

        lines = contents.lines

        obj = $1 if lines.detect { |l| l =~ /^\s+(\w+)\.name\s+=/ }
        raise "couldn't find spec object name" if obj.nil?

        new_line = "#{obj}.add_development_dependency \"manageiq-style\"\n"

        dev_lines = lines.select { |l| l.include?("add_development_dependency") }
        if dev_lines.any?
          # Add manageiq-style and remove all direct rubocop references
          dev_lines << new_line
          dev_lines.reject! { |l| l.include?("rubocop") }

          # Prepare the lines in a nice format
          format_gem_source_lines!(dev_lines)
          dev_lines.sort_by!(&:downcase)

          # Remove the old dev lines and add the new ones
          insert_at = lines.index { |l| l.include?("add_development_dependency") }
          lines.delete_if { |l| l.include?("add_development_dependency") }
          lines.insert(insert_at, dev_lines)
        else
          insert_at = -1
          insert_at -= 1 until lines[insert_at].strip != "end"
          lines.insert(insert_at, new_line)
        end

        File.write(gemspec, lines.join)
      end

      def update_gemfile
        contents = File.read("Gemfile")
        return if contents.include?("manageiq-style")

        lines = contents.lines

        new_line = "gem \"manageiq-style\", :require => false\n"

        group_index = lines.index { |l| l.match?(/group\(?\s*:development/) }
        if group_index
          # Determine the group range
          group_index += 1
          group_end = group_index
          group_end += 1 until lines[group_end].strip == "end"
          group_range = (group_index..group_end - 1)

          # Split lines into "gem" units including their preceding comments or blank lines
          gem_units = lines[group_range].slice_after { |l| l.match?(/^\s*gem/) }.to_a

          # Add manageiq-style and remove all direct rubocop references
          gem_units << [new_line]
          gem_units.reject! { |u| u.last.include?("rubocop") }

          # Prepare the lines in a nice format
          gem_lines = gem_units.map(&:last)
          format_gem_source_lines!(gem_lines)
          gem_units.each_with_index { |u, i| u[-1] = gem_lines[i] }
          gem_units.sort_by! { |u| u.last.downcase }
          gem_units.flatten!

          # Remove the old group lines and add the new ones
          lines.slice!(group_range)
          lines.insert(group_index, gem_units)
        else
          lines << <<~RUBY

            group :development do
              #{new_line}
            end
          RUBY
        end

        File.write("Gemfile", lines.join)
      end

      def format_gem_source_lines!(lines)
        indent = lines.first.match(/^\s+/).to_s

        lines.map! { |l| l.strip.gsub(/[()]/, " ").split(" ", 3) }             # Split to [prefix, gem, versions]
        lines.each { |parts| parts[1].tr!("'", "\"") }                         # Ensure double quoted gem name
        max_width = lines.map { |parts| parts[1].size }.max                    # Determine the widest gem name
        lines.each { |parts| parts[1] = parts[1].ljust(max_width, " ") }       # Apply the width
        lines.map! { |parts| parts.join(" ").strip.insert(0, indent) << "\n" } # Back to strings

        lines
      end

      def update_generator
        plugin_dir = "lib/generators/manageiq/plugin/templates"

        return unless File.directory?(plugin_dir)

        update_rubocop_yml(File.join(plugin_dir, ".rubocop.yml"))
        ensure_rubocop_local_yml_exists(File.join(plugin_dir, ".rubocop_local.yml"))
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

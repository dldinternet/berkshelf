require_relative 'dependency'

module Berkshelf
  # The object representation of the Berkshelf lockfile. The lockfile is useful
  # when working in teams where the same cookbook versions are desired across
  # multiple workstations.
  class Lockfile
    # @return [Pathname]
    #   the path to this Lockfile
    attr_reader :filepath

    # @return [Berkshelf::Berksfile]
    #   the Berksfile for this Lockfile
    attr_reader :berksfile

    # Create a new lockfile instance associated with the given Berksfile. If a
    # Lockfile exists, it is automatically loaded. Otherwise, an empty instance is
    # created and ready for use.
    #
    # @param berksfile [Berkshelf::Berksfile]
    #   the Berksfile associated with this Lockfile
    def initialize(berksfile)
      @berksfile    = berksfile
      @filepath     = File.expand_path("#{berksfile.filepath}.lock")
      @dependencies = {}

      load! if File.exists?(@filepath)
    end

    # Load the lockfile from file system.
    def load!
      contents = File.read(filepath).strip
      hash     = parse(contents)

      hash[:dependencies].each do |name, options|
        add(Berkshelf::Dependency.new(berksfile, name.to_s, options))
      end
    end

    # Set the sha value to nil to mark that the lockfile is not out of
    # sync with the Berksfile.
    def reset_sha!
      @sha = nil
    end

    # The list of dependencies constrained in this lockfile.
    #
    # @return [Array<Berkshelf::Dependency>]
    #   the list of dependencies in this lockfile
    def dependencies
      @dependencies.values
    end

    # Find the given dependency in this lockfile. This method accepts a dependency
    # attribute which may either be the name of a cookbook (String) or an
    # actual cookbook dependency.
    #
    # @param [String, Berkshelf::Dependency] dependency
    #   the cookbook dependency/name to find
    # @return [Berkshelf::Dependency, nil]
    #   the cookbook dependency from this lockfile or nil if one was not found
    def find(dependency)
      @dependencies[cookbook_name(dependency).to_s]
    end

    # Determine if this lockfile contains the given dependency.
    #
    # @param [String, Berkshelf::Dependency] dependency
    #   the cookbook dependency/name to determine existence of
    # @return [Boolean]
    #   true if the dependency exists, false otherwise
    def has_dependency?(dependency)
      !find(dependency).nil?
    end

    # Replace the current list of dependencies with `dependencies`. This method does
    # not write out the lockfile - it only changes the state of the object.
    #
    # @param [Array<Berkshelf::Dependency>] dependencies
    #   the list of dependencies to update
    def update(dependencies)
      reset_dependencies!

      dependencies.each { |dependency| append(dependency) }
      save
    end

    # Add the given dependency to the `dependencies` list, if it doesn't already exist.
    #
    # @param [Berkshelf::Dependency] dependency
    #   the dependency to append to the dependencies list
    def add(dependency)
      @dependencies[cookbook_name(dependency)] = dependency
    end
    alias_method :append, :add

    # Remove the given dependency from this lockfile. This method accepts a dependency
    # attribute which may either be the name of a cookbook (String) or an
    # actual cookbook dependency.
    #
    # @param [String, Berkshelf::Dependency] dependency
    #   the cookbook dependency/name to remove
    #
    # @raise [Berkshelf::CookbookNotFound]
    #   if the provided dependency does not exist
    def remove(dependency)
      unless has_dependency?(dependency)
        raise Berkshelf::CookbookNotFound, "'#{cookbook_name(dependency)}' does not exist in this lockfile!"
      end

      @dependencies.delete(cookbook_name(dependency))
    end
    alias_method :unlock, :remove

    # @return [String]
    #   the string representation of the lockfile
    def to_s
      "#<Berkshelf::Lockfile #{Pathname.new(filepath).basename}>"
    end

    # @return [String]
    #   the detailed string representation of the lockfile
    def inspect
      "#<Berkshelf::Lockfile #{Pathname.new(filepath).basename}, dependencies: #{dependencies.inspect}>"
    end

    # Write the current lockfile to a hash
    #
    # @return [Hash]
    #   the hash representation of this lockfile
    #   * :dependencies [Array<Berkshelf::Dependency>] the list of dependencies
    def to_hash
      {
        dependencies: @dependencies
      }
    end

    # The JSON representation of this lockfile
    #
    # Relies on {#to_hash} to generate the json
    #
    # @return [String]
    #   the JSON representation of this lockfile
    def to_json(options = {})
      JSON.pretty_generate(to_hash, options)
    end

    private

      # Parse the given string as JSON.
      #
      # @param [String] contents
      #
      # @return [Hash]
      def parse(contents)
        # Ruby's JSON.parse cannot handle an empty string/file
        return { dependencies: [] } if contents.strip.empty?

        hash = JSON.parse(contents, symbolize_names: true)

        # Legacy support for 2.0 lockfiles
        # @todo Remove in 4.0
        if hash[:sources]
          LockfileLegacy.warn!
          hash[:dependencies] = hash.delete(:sources)
        end

        return hash
      rescue Exception => e
        # Legacy support for 1.0 lockfiles
        # @todo Remove in 4.0
        if e.class == JSON::ParserError && contents =~ /^cookbook ["'](.+)["']/
          LockfileLegacy.warn!
          return LockfileLegacy.parse(berksfile, contents)
        else
          raise Berkshelf::LockfileParserError.new(filepath, e)
        end
      end

      # Save the contents of the lockfile to disk.
      def save
        File.open(filepath, 'w') do |file|
          file.write to_json + "\n"
        end
      end

      def reset_dependencies!
        @dependencies = {}
      end

      # Return the name of this cookbook (because it's the key in our
      # table).
      #
      # @param [Berkshelf::Dependency, #to_s] dependency
      #   the dependency to find the name from
      #
      # @return [String]
      #   the name of the cookbook
      def cookbook_name(dependency)
        dependency.is_a?(Berkshelf::Dependency) ? dependency.name : dependency.to_s
      end

      # Legacy support for old lockfiles
      #
      # @todo Remove this class in Berkshelf 3.0.0
      class LockfileLegacy
        class << self
          # Read the old lockfile content and instance eval in context.
          #
          # @param [Berkshelf::Berksfile] berksfile
          #   the associated berksfile
          # @param [String] content
          #   the string content read from a legacy lockfile
          def parse(berksfile, content)
            dependencies = {}.tap do |hash|
              content.split("\n").each do |line|
                next if line.empty?
                dependency            = new(berksfile, line)
                hash[dependency.name] = dependency.options
              end
            end

            {
              dependencies: dependencies,
            }
          end

          # Warn the user they he/she is using an old Lockfile format.
          #
          # This automatically outputs to the {Berkshelf.ui}; nothing is
          # returned.
          #
          # @return [nil]
          def warn!
            Berkshelf.ui.warn(warning_message)
          end

          private
            # @return [String]
            def warning_message
              'You are using the old lockfile format. Attempting to convert...'
            end
        end

        # @return [Hash]
        #   the hash of options
        attr_reader :options

        # @return [String]
        #   the name of this cookbook
        attr_reader :name

        # @return [Berkshelf::Berksfile]
        #   the berksfile
        attr_reader :berksfile

        # Create a new legacy lockfile for processing
        #
        # @param [String] content
        #   the content to parse out and convert to a hash
        def initialize(berksfile, content)
          @berksfile = berksfile
          instance_eval(content).to_hash
        end

        # Method defined in legacy lockfiles (since we are using instance_eval).
        #
        # @param [String] name
        #   the name of this cookbook
        # @option options [String] :locked_version
        #   the locked version of this cookbook
        def cookbook(name, options = {})
          @name    = name
          @options = manipulate(options)
        end

        private

          # Perform various manipulations on the hash.
          #
          # @param [Hash] options
          def manipulate(options = {})
            if options[:path]
              options[:path] = berksfile.find(name).instance_variable_get(:@options)[:path] || options[:path]
            end
            options
          end
      end
  end
end

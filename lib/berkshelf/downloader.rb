require_relative 'dependency'
require_relative 'location'

module Berkshelf
  class Downloader
    extend Forwardable

    DEFAULT_LOCATIONS = [
      {
        type: :site,
        value: Location::OPSCODE_COMMUNITY_API,
        options: Hash.new
      }
    ]

    # @return [String]
    #   a filepath to download dependencies to
    attr_reader :cookbook_store

    def_delegators :@cookbook_store, :storage_path

    # @option options [Array<Hash>] locations
    def initialize(cookbook_store, options = {})
      @cookbook_store = cookbook_store
      @locations = options.fetch(:locations, Array.new)
    end

    # @return [Array<Hash>]
    #   an Array of Hashes representing each default location that can be used to attempt
    #   to download dependencies which do not have an explicit location. An array of default locations will
    #   be used if no locations are explicitly added by the {#add_location} function.
    def locations
      @locations.any? ? @locations : DEFAULT_LOCATIONS
    end

    # Create a location hash and add it to the end of the array of locations.
    #
    # subject.add_location(:chef_api, "http://chef:8080", node_name: "reset", client_key: "/Users/reset/.chef/reset.pem") =>
    #   [ { type: :chef_api, value: "http://chef:8080/", node_name: "reset", client_key: "/Users/reset/.chef/reset.pem" } ]
    #
    # @param [Symbol] type
    # @param [String, Symbol] value
    # @param [Hash] options
    #
    # @return [Hash]
    def add_location(type, value, options = {})
      if has_location?(type, value)
        raise DuplicateLocationDefined,
          "A default '#{type}' location with the value '#{value}' is already defined"
      end

      @locations.push(type: type, value: value, options: options)
    end

    # Checks the list of default locations if a location of the given type and value has already
    # been added and returns true or false.
    #
    # @return [Boolean]
    def has_location?(type, value)
      @locations.select { |loc| loc[:type] == type && loc[:value] == value }.any?
    end

    # Download the given Berkshelf::Dependency.
    #
    # @param [Berkshelf::Dependency] dependency
    #   the dependency to download
    #
    # @return [Array]
    #   an array containing the downloaded CachedCookbook and the Location used
    #   to download the cookbook
    def download(dependency)
      if dependency.location
        begin
          location = dependency.location
          cached   = download_location(dependency, location, true)
          dependency.cached_cookbook = cached

          return [cached, location]
        rescue => e
          raise if e.kind_of?(CookbookValidationFailure)
          Berkshelf.formatter.error "Failed to download '#{dependency.name}' from #{dependency.location}"
        end
      else
        locations.each do |loc|
          options = loc[:options].merge(loc[:type] => loc[:value])
          location = Location.init(dependency.name, dependency.version_constraint, options)

          cached = download_location(dependency, location)
          if cached
            dependency.cached_cookbook = cached
            return [cached, location]
          end
        end
      end

      raise CookbookNotFound, "Cookbook '#{dependency.name}' not found in any of the default locations"
    end

    private

      # Attempt to download the dependency from the given location. If the dependency does
      # not explicity specify a location to retrieve it from, the downloader will attempt to
      # retrieve the dependency from each of the default locations until it is found.
      #
      # @note
      #   a dependency is said to have an explicit location if it has a value for {#location}
      #
      # @note
      #   an error will be raised if `raise_if_not_found` is specified.
      #
      # @raise [Bershelf::CookbookNotFound]
      #   if `raise_if_not_found` is true and the dependency could not be
      #   downloaded
      #
      # @param [Berkshelf::Dependency] dependency
      #   the dependency to download
      # @param [~Berkshelf::Location] location
      #   the location to download from
      # @param [Boolean] raise_if_not_found
      #   raise a {Berkshelf::CookbookNotFound} error if true, otherwise,
      #   return nil
      #
      # @return [Berkshelf::CachedCookbook, nil]
      #   the downloaded cached cookbook, or nil if one was not found
<<<<<<< HEAD
      def download_location(dependency, location, raise_if_not_found = false)
        from_cache(dependency) || location.download(storage_path)
=======
      def download_location(source, location, raise_if_not_found = false)
        location.download(storage_path)
>>>>>>> e253d0c... Force locked_version on version_constraint (fixes #637)
      rescue Berkshelf::CookbookNotFound
        raise if raise_if_not_found
        nil
      end
<<<<<<< HEAD

      # Load the cached cookbook from the cookbook store.
      #
      # @param [Berkshelf::CookbookSource] dependency
      #   the dependency to find in the cache
      #
      # @return [Berkshelf::CachedCookbook, nil]
      def from_cache(dependency)
        # Can't safely read a git location from cache
        return nil if dependency.location.kind_of?(Berkshelf::GitLocation)

        if dependency.locked_version
          cookbook = cookbook_store.cookbook_path(dependency.name, dependency.locked_version)
          path = File.expand_path(File.join(storage_path, cookbook))

          return nil unless File.exists?(path)
          return Berkshelf::CachedCookbook.from_path(path, name: dependency.name)
        end

        cookbook_store.satisfy(dependency.name, dependency.version_constraint)
      end
=======
>>>>>>> e253d0c... Force locked_version on version_constraint (fixes #637)
  end
end

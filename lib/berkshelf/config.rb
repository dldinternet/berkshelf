require 'buff/config/json'

module Berkshelf
  class Config < Buff::Config::JSON
    class << self
      # @return [String]
      def store_location
        File.join(Berkshelf.berkshelf_path, 'config.json')
      end

      # @return [String]
      def local_location
        ENV['BERKSHELF_CONFIG'] || File.join('.', '.berkshelf', 'config.json')
      end

      # @return [String]
      def path
        path = File.exists?(local_location) ? local_location : store_location
        File.expand_path(path)
      end

      # @param [String] new_path
      def set_path(new_path)
        @instance = nil
      end

      # @return [String, nil]
      #   the contents of the file
      def file
        File.read(path) if File.exists?(path)
      end

      # Instantiate and return or just return the currently instantiated Berkshelf
      # configuration
      #
      # @return [Config]
      def instance
        @instance ||= if file
          from_json file
        else
          new
        end
      end

      # Reload the currently instantiated Berkshelf configuration
      #
      # @return [Config]
      def reload
        @instance = nil
        self.instance
      end
    end

    # @param [String] path
    # @param [Hash] options
    #   @see {Buff::Config::JSON}
    def initialize(path = self.class.path, options = {})
      super(path, options)
    end

    # The string representation of the Config.
    #
    # @return [String]
    def to_s
      "#<#{self.class}>"
    end

    # The detailed string representation of the Config.
    #
    # @return [String]
    def inspect
      "#<#{self.class} #{to_hash.inspect}>"
    end

    attribute 'chef.chef_server_url',
      type: String,
      default: Berkshelf.chef_config.chef_server_url
    attribute 'chef.validation_client_name',
      type: String,
      default: Berkshelf.chef_config.validation_client_name
    attribute 'chef.validation_key_path',
      type: String,
      default: Berkshelf.chef_config.validation_key
    attribute 'chef.client_key',
      type: String,
      default: Berkshelf.chef_config.client_key
    attribute 'chef.node_name',
      type: String,
      default: Berkshelf.chef_config.node_name
    attribute 'cookbook.copyright',
      type: String,
      default: Berkshelf.chef_config.cookbook_copyright
    attribute 'cookbook.email',
      type: String,
      default: Berkshelf.chef_config.cookbook_email
    attribute 'cookbook.license',
      type: String,
      default: Berkshelf.chef_config.cookbook_license
    attribute 'allowed_licenses',
      type: Array,
      default: Array.new
    attribute 'raise_license_exception',
      type: Boolean,
      default: false
    attribute 'vagrant.vm.box',
      type: String,
      default: 'Berkshelf-CentOS-6.3-x86_64-minimal',
      required: true
    attribute 'vagrant.vm.box_url',
      type: String,
      default: 'https://dl.dropbox.com/u/31081437/Berkshelf-CentOS-6.3-x86_64-minimal.box',
      required: true
    attribute 'vagrant.vm.forward_port',
      type: Hash,
      default: Hash.new
    attribute 'vagrant.vm.network.bridged',
      type: Boolean,
      default: false
    attribute 'vagrant.vm.network.hostonly',
      type: String,
      default: '33.33.33.10'
    attribute 'vagrant.vm.provision',
      type: String,
      default: 'chef_solo'
    attribute 'ssl.verify',
      type: Boolean,
      default: true,
      required: true
  end
end

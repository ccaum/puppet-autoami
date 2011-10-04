module Puppet::CloudPack
  class << self

    def add_new_ami_options(action)
      add_region_option(action)
      add_platform_option(action)

      action.option '--description=' do
        summary 'The description for the AMI'
        description <<-EOT
          The description will be assigned to the description
          for the generated AMI
        EOT
        required
      end

      action.option '--manifest_version=' do
        summary 'Puppet Manifest Version'
        description <<-EOT
          The Puppet Manifest version used to generate the AMI.
          It is used as the identifier of the AMI
        EOT
        required
      end
    end

    def list_instances(connection, parameter, value)
      yaml = IO.read('/var/lib/puppet/cloudscale/db.marshal')
      state = YAML.load( yaml )

      state['running_instances']
    end

    def load_instances(options)
      Puppet.info "Connecting to #{options[:platform]} ..."
      connection =  create_connection(options)
      Puppet.info "Connecting to #{options[:platform]} ... Done"

      config.images.each do |image|
        options['image'] = image
        Puppet::Face[:node_aws, '0.0.1'].bootstrap options
      end
    end

    def find_instance(connection, parameter, value)
      connection.servers.each do |server|
        #Allow us to be able to find instances based on any parameter
        #  Parameter must be to symbol
        if server.send(parameter) == value
          return server
        end
      end
    end

    def bootstrap_cloudscale(options)
      server = self.create(options)
      options[:certname] = "#{options[:certname]}_#{server}"
      sleep 60
      self.init(server, options)
      return nil
    end

    def images(options)
      options = merge_default_options(options)

      Puppet.info "Connecting to #{options[:platform]} ..."
      connection =  create_connection(options)
      Puppet.info "Connecting to #{options[:platform]} ... Done"

      connection.images.all('Owner' => 'self').map do |image|
        image.id
      end
    end

    def new_ami(server, options={})
      options = merge_default_options(options)

      Puppet.info "Connecting to #{options[:platform]} ..."
      connection =  create_connection(options)
      Puppet.info "Connecting to #{options[:platform]} ... Done"

      #Find our instance
      instance = find_instance(connection, :dns_name, server)

      image_data = connection.create_image(instance.identity, "v_#{options[:manifest_version]}", options[:description])

      #We're done with out instace. Get rid of it, unless told not to
      if options[:terminate]
        Puppet::Face[:node, '0.0.1'].terminate(server)
      end

      image_data.body['imageId']
    end
  end
end

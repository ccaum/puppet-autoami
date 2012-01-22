module Puppet::CloudPack
  class << self

    require 'mysql'
    require 'parseconfig'

    def dbh
      config_file = '/etc/cloudscale.conf'
      config = ParseConfig.new(config_file).params['mysql']
      Mysql.new(host=config['host'], user=config['username'], password=config['password']).select_db(config['database'])
    end

    def add_new_group_options(action)
      action.option '--image=' do
        summary 'The AMI to use with the group'
        required
      end

      action.option '--type=' do
        summary 'The EC2 instance type to launch'
        required
      end

      action.option '--keyname=' do
        summary 'The public keypair name to use'
        required
      end

      action.option '--keyfile=' do
        summary 'Path on disk to private key associated with keyname'
        required
      end

      action.option '--login=' do
        summary 'Login user to ssh in with to manage puppet'
        description <<-EOT
          The login user must be root or a user capable of running
          sudo without a password
        EOT
        required
      end

      action.option '--server=' do
        summary 'Puppet master server'
      end

      action.option '--region=' do
        summary 'EC2 region to launch the instances in'
      end

      action.option '--node-group=' do
        summary 'Console node group to add the instance to'
      end
    end

    def load_ami_groups
      groups_hash = Hash.new
      dbh.query('SELECT * FROM groups').each_hash do |group|
        groups_hash[group['name']] = { :image   => group['image'],
                               :type    => group['type'],
                               :keyname => group['keyname'],
                               :keyfile => group['keyfile'],
                               :login   => group['login'],
                               :server  => group['server'],
                               :region  => group['region']
        }
      end

      groups_hash.each do |agroup,props|
        server = Puppet::Face[:node_aws, :current].create :region => props[:region],
          :keyname => props[:keyname],
          :image   => props[:image],
          :type    => props[:type]

        Puppet::Face[:node_aws, :current].init(server, {
          :keyfile => props[:keyfile],
          :server  => props[:server],
          :login   => props[:login],
          :install_script => 'autoami',
          :puppetagent_certname => server,
          :node_group => props[:node_group] }
        )

        dbh.query("INSERT INTO nodes ( dns_name, ami_group ) VALUES ( '#{server}', '#{agroup}')")
      end
    end

    def groups
      groups_hash = Hash.new
      dbh.query("SELECT * FROM groups").each_hash do |group|
        groups_hash[group['name']] = { :image   => group['image'],
                               :type    => group['type'],
                               :keyname => group['keyname'],
                               :keyfile => group['keyfile'],
                               :login   => group['login'],
                               :server  => group['server'],
                               :region  => group['region'],
                               :node_group => group['node_group']
        }
      end
      groups_hash
    end

    def delete_group(group)
      dbh.query("DELETE FROM groups WHERE name='#{group}'")
    end

    def new_group(group, options)
      dbh.query("INSERT INTO groups ( name, image, type, keyname, keyfile, login, server, region, node_group) VALUES ( '#{group}', '#{options[:image]}', '#{options[:type]}', '#{options[:keyname]}', '#{options[:keyfile]}', '#{options[:login]}', '#{options[:server]}', '#{options[:region]}', '#{options[:node_group]}')")
    end

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

      action.option '--terminate' do
        summary 'Terminate the instance after generating the AMI'
        description <<-EOT
          The instance can be terminated after it has been
          snapshotted and the new AMI is produced
        EOT
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

      #If told, destroy the instance
      if options[:terminate]
        Puppet::Face[:node_aws, :current].terminate(server)
      end

      image_data.body['imageId']
    end
  end
end

module Puppet::CloudPack
  class << self

    require 'mysql'
    require 'parseconfig'

    def dbh
      return @dbh if @dbh

      config_file = "#{Puppet['confdir']}/autoami.conf"
      config = ParseConfig.new(config_file).params['mysql']
      @dbh = Mysql.new(host=config['host'], user=config['username'], password=config['password']).select_db(config['database'])
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

      action.option '--enc-user=' do
        summary 'The ENC user to authenticate as for classification'
        required
      end

      action.option '--enc-pass=' do
        summary 'The ENC user password to authenticate as for classification'
        required
      end

      action.option '--enc-port=' do
        summary 'The port to access the ENC on for classification'

        default_to { '443' }
      end

      action.option '--enc-server=' do
        summary 'The location of the ENC for classification'
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

      action.option '--puppetserver=' do
        summary 'Puppet master server'
      end

      action.option '--region=' do
        summary 'EC2 region to launch the instances in'

        default_to { 'us-east-1' }
      end

      action.option '--node-group=' do
        summary 'Console node group to add the instance to'
      end
    end

    def current_instances
      nodes = Hash.new
      dbh.query('SELECT * FROM nodes').each_hash do |node|
        dns_name  = node['dns_name']
        ami_group = node['ami_group']

        unless instance = Puppet::Face[:node_aws, :current].list.find { |id,values| values['dns_name'] == dns_name }

          Puppet.warning "Instance #{dns_name} no longer exists but never reported.  Removing from list. You might want to run autoami again"
          dbh.query("DELETE FROM nodes WHERE dns_name='#{dns_name}'")
          return
        end

        nodes[instance[1]['id']] = instance[1]
      end

      nodes
    end

    def get_props(group)
      group_props = Hash.new
      dbh.query("SELECT * FROM groups WHERE name='#{group}'").each_hash do |group|
        group_props = { :image   => group['image'],
                        :type    => group['type'],
                        :keyname => group['keyname'],
                        :keyfile => group['keyfile'],
                        :login   => group['login'],
                        :server  => group['server'],
                        :node_group => group['node_group'],
                        :enc_server => group['enc_server'],
                        :enc_user   => group['enc_user'],
                        :enc_pass   => group['enc_pass'],
                        :enc_port   => group['enc_port'],
                        :region  => group['region']
        }
      end
      group_props
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
                               :node_group => group['node_group'],
                               :enc_server => group['enc_server'],
                               :enc_user   => group['enc_user'],
                               :enc_pass   => group['enc_pass'],
                               :enc_port   => group['enc_port'],
                               :region  => group['region']
        }
      end

      groups_hash.each do |agroup,props|
        launch_instance agroup, props

        Puppet.info 'Running puppet agent'
        command_prefix = props[:login] == 'root' ? '' : 'sudo '
        ssh_remote_execute(server, props[:login], "#{command_prefix} puppet agent -t", props[:keyfile])
      end
    end

    def launch_instance(group, props)
      server = Puppet::Face[:node_aws, :current].create :region => props[:region],
        :keyname => props[:keyname],
        :image   => props[:image],
        :type    => props[:type],
        :tags    => 'Created-By-Tool=Autoami'

      dbh.query("INSERT INTO nodes ( dns_name, ami_group ) VALUES ( '#{server}', '#{group}')")

      Puppet::Face[:node, :current].init(server, {
        :keyfile => props[:keyfile],
        :server  => props[:server],
        :login   => props[:login],
        :install_script => 'autoami',
        :enc_auth_user => props[:enc_user],
        :enc_auth_passwd => props[:enc_pass],
        :enc_port      => props[:enc_port],
        :enc_server    => props[:enc_server],
        :enc_ssl       => true,
        :puppetagent_certname => server,
        :node_group => props[:node_group] }
      )

      server
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
                               :enc_server => group['enc_server'],
                               :enc_user   => group['enc_user'],
                               :enc_pass   => group['enc_pass'],
                               :enc_port   => group['enc_port'],
                               :node_group => group['node_group']
        }
      end
      groups_hash
    end

    def delete_group(group)
      dbh.query("DELETE FROM groups WHERE name='#{group}'")
    end

    def new_group(group, options)
      enc_server = options[:enc_server] || options[:puppetserver]

      dbh.query("INSERT INTO groups ( name, image, type, keyname, keyfile, login, server, region, node_group, enc_server, enc_port, enc_user, enc_pass) VALUES ( '#{group}', '#{options[:image]}', '#{options[:type]}', '#{options[:keyname]}', '#{options[:keyfile]}', '#{options[:login]}', '#{options[:puppetserver]}', '#{options[:region]}', '#{options[:node_group]}', '#{enc_server}', '#{options[:enc_port]}', '#{options[:enc_user]}', '#{options[:enc_pass]}')")
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

      action.option '--manifest-version=' do
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
      Puppet.info "Connecting to #{options[:platform]} ..."
      connection =  create_connection(options)
      Puppet.info "Connecting to #{options[:platform]} ... Done"

      images_info = Hash.new
      connection.images.all('Owner' => 'self').each do |image|
        images_info[image.id] = { 'name'             => image.name,
                     'architecture'     => image.architecture,
                     'description'      => image.description,
                     'state'            => image.state,
                     'is_public'        => image.is_public,
                     'root_device_type' => image.root_device_type
                   }
      end

      images_info
    end

    def new_ami(server, options={})
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

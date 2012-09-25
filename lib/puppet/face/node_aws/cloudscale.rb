require 'puppet/cloudpack'
require 'puppet/cloudscale'

Puppet::Face.define :node_aws, '0.0.1' do
  action :images do
    summary 'List available images'
    description <<-EOT
      Lists all available images owned by the account configured by fog
    EOT

    Puppet::CloudPack.add_platform_option(self)
    when_invoked do |options|
      Puppet::CloudPack.images(options)
    end

    when_rendering :console do |images|
      images.map do |name, properties|
        "#{name}:\n" + \
        properties.map do |pname,value|
          "    #{pname}: #{value}"
        end.join("\n")
      end.join("\n")
    end
  end

  action :new_ami do
    summary 'Update an EBS backed AMI from an instance'
    description <<-EOT
      Generates a new AMI from an running instance.  The instance will be
      rebooted in order to snapshot it.
    EOT
    Puppet::CloudPack.add_new_ami_options(self)
    when_invoked do |server, options|
      Puppet::CloudPack.new_ami(server,options)
    end
  end

  action :launch do
    summary 'Launch an instance of an AutoAMI group'
    description <<-EOT
      Launch an instance of an AutoAMI group using the latest
      AMI image
    EOT

    when_invoked do |group, options|
      properties = Puppet::CloudPack.get_props(group)
      Puppet::CloudPack.launch_instance(group, properties)
    end

    when_rendering :console do |value|
      "Succesfully launched instance at #{value}"
    end
  end
end

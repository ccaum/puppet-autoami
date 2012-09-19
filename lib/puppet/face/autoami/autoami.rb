require 'puppet/cloudpack'
require 'puppet/cloudscale'

Puppet::Face.define :autoami, '0.0.1' do
  action :new_group do
    summary 'Create a new autoami group'

    Puppet::CloudPack.add_new_group_options(self)
    when_invoked do |name, options|
      Puppet::CloudPack.new_group(name, options)
    end

    when_rendering :console do |result|
      result.inspect
    end
  end

  action :delete_group do
    summary 'Delete an image group'

    when_invoked do |ami_group, options|
      Puppet::CloudPack.delete_group ami_group
    end
  end

  action :run do
    summary 'Begin an autoami run'

    when_invoked do
      Puppet::CloudPack.load_ami_groups
    end
  end

  action :list do
    summary 'List active instances'

    when_invoked do
      Puppet::CloudPack.current_instances
    end

    when_rendering :console do |result|
      result.to_yaml
    end
  end

  action :groups do
    summary 'List autoami groups'

    when_invoked do
      Puppet::CloudPack.groups
    end

    when_rendering :console do |result|
      if result.empty?
        "No groups found"
      else
        result.map do |key, values|
          "#{key}:\n" +
            values.map do |name,val|
              "  #{name}:  #{val}"
            end.join("\n")
        end.join("\n")
      end
    end
  end
end

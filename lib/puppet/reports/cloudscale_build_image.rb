require 'puppet'
require 'puppet/face'
require 'uri'

Puppet::Reports.register_report(:cloudscale_build_image) do

  desc <<-DESC
  Determines whether a new AMI should be made based on the existence of changed resources on a fully successul Puppet run.  Cloud Provisioner is a requirement for this processor to function properly
  DESC

  def process
    if File.exists? '/var/cache/cloudscale/nodes.yaml'
      nodes = YAML.load(IO.read('/var/cache/cloudscale/nodes.yaml'))
    else
      raise 'Cannot locate /var/cache/cloudscale/nodes.yaml script'
    end

    #If the reporting node matches any of our groups
    if nodes.include? self.host
      node = Puppet::Face[:node_aws, :current]

      changed = metrics['resources']['changed']
      failed  = metrics['resources']['failed']
    
      if changed > 0 and failed == 0
        #Generate the new AMI and terminate the instance
        new_image = node.new_ami self.host, 
          :manifest_version => self.configuration_version, 
          :description => "#{group} Manifest version #{self.configuration_version}", 

        #Wait until we have our image built
        loop {
          break if Puppet::Face[:node_aws, :current].images.include? new_image
          sleep 1
        }

        node.terminate self.host
      end
    end
  end
end

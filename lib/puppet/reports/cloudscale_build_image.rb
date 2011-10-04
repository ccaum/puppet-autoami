require 'puppet'
require 'puppet/face'
require 'uri'

Puppet::Reports.register_report(:cloudscale_build_image) do

  desc <<-DESC
  Determines whether a new AMI should be made based on the existence of changed resources on a fully successul Puppet run.  Cloud Provisioner is a requirement for this processor to function properly
  DESC

  def update_ami

  end

  def process
    begin
      require 'parseconfig'

      config = ParseConfig.new('/etc/cloudscale.conf')
      groups = config.groups
    rescue => e
      raise "Could not parse config file /etc/cloudscale.conf: #{e}"
    end

    #If the reporting node matches any of our groups
    groups.each do |group|
      if self.host =~ /^#{group}_/
        node = Puppet::Face[:node, '0.0.1']

        dns_name = self.host.split('_',2)[1]

        changed = metrics['resources']['changed']
        failed  = metrics['resources']['failed']
      
        if changed > 0 and failed == 0
          #Generate the new AMI and terminate the instance
          new_image = node.new_ami dns_name, :manifest_version => self.configuration_version, :description => "#{group} Manifest version #{self.configuration_version}"

          #Wait until we have our image built
          loop {
            break if Puppet::Face[:node, '0.0.1'].images.include? new_image
            sleep 1
          }

          node.terminate dns_name
        end
      end
    end
  end
end

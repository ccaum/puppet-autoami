require 'puppet'
require 'puppet/face'
require 'uri'
require 'mysql'
require 'parseconfig'

Puppet::Reports.register_report(:autoami) do

  desc <<-DESC
  Determines whether a new AMI should be made based on the existence of changed resources on a fully successul Puppet run.  Cloud Provisioner is a requirement for this processor to function properly
  DESC

  def process
    begin
      config_file = "#{Puppet['confdir']}/autoami.conf"
      config = ParseConfig.new(config_file).params['mysql']
      dbh = Mysql.new(host=config['host'], user=config['username'], password=config['password']).select_db(config['database'])
    rescue => e
      raise "Could not connect to database: #{e}"
    end

    found = false
    ami_group = String.new
    dbh.query("SELECT dns_name,ami_group FROM nodes").each_hash do |node|
      #This is much more efficient
      if node['dns_name'] == self.host
        ami_group = node['ami_group']
        found = true
        break
      end
    end

    #If the reporting node matches any of our groups
    if found
      node = Puppet::Face[:node_aws, :current]

      changed = metrics['resources']['changed']
      failed  = metrics['resources']['failed']

      if changed > 0 and failed == 0
        #Generate the new AMI
        new_image = node.new_ami self.host,
          :manifest_version => self.configuration_version,
          :description => "#{ami_group} Manifest version #{self.configuration_version}"

        dbh.query("SELECT image FROM groups WHERE name='#{ami_group}'").each_hash do |agroup|
          old_image = agroup['image']
        end

        #Wait until we have our image built
        loop {
          images = Puppet::Face[:node_aws, :current].images
          if images.keys.include?(new_image) and images[new_image]['state'] == 'available'
            dbh.query("UPDATE groups SET image='#{new_image}' WHERE name='#{ami_group}'")
            break
          end
          sleep 1
        }
      end

      #Delete the host
      dbh.query("DELETE FROM nodes WHERE dns_name='#{self.host}'")
      Puppet::Face[:node_aws, :current].terminate self.host
    end
  end
end

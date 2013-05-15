Automatically Generating AMIs using Puppet

About
=====

AutoAMI is an image management system that tracks changes to your EBS backed
AMIs by processing Puppet reports.  AutoAMI will update your EBS backed AMIs
automatically when Puppet changes are made.

The Problem
-----------

Baking new AMIs can be tedious.  There are several tools out there to help with
this process, but it's difficult to know when to update your AMIs, how to keep
track of them, and to autonomously detect changes so you know you're not
updating the AMI for no reason. 

Or you can take the route of not doing image management at all and use only a 
single AMI that contains nothing but an OS and Puppet.  When the new instance
is created, a role is assigned to it and Puppet configures the instance.  The
problem with this approach is it can take quite a while for Puppet to configure
the new instance.  If you just created many instances, time is probably of the 
essence.  

A solution briging the best of both techniques is required.

The Solution
------------

Puppet knows about all the configuration that goes in to your instances.
Puppet knows what is required for a database, a wordpress server, etc.
Further, Puppet can detect changes in the requirements to fulfill a given role,
or type, of instance.  Therefore Puppet is the best tool to use to detect
changes to your instance roles.

Using a Puppet report processor, new instances can be tracked for changes.  If 
changes occur, update the AMI from a running instance.

How it works 
------------

Using `puppet autoami new_group` you can specify **groups** of instances. Think
of them more as roles.  You can specify a database group, a wordpress group, or
a load balancer group, to give a few examples.  When `puppet autoami run` is
run, a single instance of each group will be created and classified as well as
the puppet agent doing a single run.  When the agent sends its report to the
Puppet master, the report is processed for sucecssful changes. If there are
any, the instance is snapshotted and a new AMI is created from the snapshot.
The group is updated with the new, latest, image.  

Typically, you'll want to run `puppet autoami run` from a git post merge hook.
There are many other triggers you could use.  For example, a new package
build from your CI system could trigger the run.

Installing the module
=====================

`puppet module install ccaum-autoami`

Use (pluginsync|http://docs.puppetlabs.com/guides/plugins_in_modules.html#enabling-pluginsync) to sync the report processor on the Puppet master.


Set up
======

AutoAMI requires a MySQL database.  The autoami module can use the
puppetlabs-mysql module to manage the database for you. You can also use the
puppetlabs-mysql module to install a mysql server on the host you plan to use
AutoAMI on.  For example:

```puppet
class { 'mysql::server':
  config_hash { 'root_password' => 'mysql_root_password' },
} ->

class { 'autoami':
  manage_db   => true,
  db_user     => 'autoami',
  db_password => 'autoamipassword',
  db_name     => 'autoami',
}
```

The above code will install a mysql server on the host this code is declared
on, and install an autoami database.  

Using your own DB 
----------------- 

Alternatively, you can set up your own
database.  Just don't declare the **mysql::server** class and set **manage_db**
to false.  The ***db_host*** and ***db_port*** parameters in the **autoami**
class are available.

Allowing for certificate signing
--------------------------------

When AutoAMI creates new instances, it needs to be able to sign their
certificates on the Puppet master.  This requires modifying the **auth.conf**
file in your puppet configuration directory. (You can get your configuration
directory by using `puppet --configprint confdir`) 

Ensure these lines are one of the first:

```
path /certificate_status
method save
auth yes
allow {certname_of_node_with_autoami}
```

Adding the report processor
---------------------------

In order for AutoAMI to work, the Puppet master(s) must have the autoami report processor activated.
You can add the report processor to the Puppet master configuration by modifying the puppet.conf file.
Make sure you have autoami in the list of the **reports** parameter

```
[master]
  ...
  reports = https, autoami
  ...
```

Multiple Puppet Masters
-----------------------

Each Puppet master needs to have AutoAMI configured and the autoami report processor available.
Each Puppet master also must have access to the MySQL database you're using to store AutoAMI data.

Using 
=====

To get a list of available commands, use `puppet help autoami`.  You can get
more information on each subcommand by typing `puppet help autoami <subcommand>`

Setting up a group
------------------

To get a list of all required information, use `puppet help autoami new_group`.

To create a new group, use 
```
puppet autoami new_group --enc-user <enc_user_password> \
  --enc-pass <enc_user_password> \
  --image <ami> \
  --keyfile </path/to/ec2/rsa/key/file> \
  --keyname <ec2_keyname> \
  --login <user_to_login_to_ami_instance_as> \
  --node-group <group_in_console_to_add_instance_to> \
  --puppetserver <puppet_master> \
  --type <ec2_type> <name_of_group>
```

This may seem like a lot of parameters, but you won't have to specify them again.

Running
-------

To run an instance of all defined groups and check for necessary updates, use
the `puppet autoami run` command.  This will create an instance of each group,
check if puppet changed something, and if so update the AMI.

Launching a single instance
---------------------------

The ccaum-autoami module extends the `puppet node_aws` subcommand.  In addition to the
`puppet node_aws images` and `puppet node_aws new_ami` subcommands, the 
`puppet node_aws launch` subcommand is available.  This subcommand allows you to launch
a single instance of an autoami group.  For example, `puppet node_aws launch wordpress`

Manually creating a new AMI
---------------------------

If you have an instance of a EBS backed AMI running, you can create a new AMI from that
instance using the `puppet node_aws new_ami <ec2_public_dns_address.amazon.com>` 
command

Listing Available AMIs
----------------------

The `puppet node_aws images` subcommand will list all the AMIs generated and owned by 
you, including those made by AutoAMI.

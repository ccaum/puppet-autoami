Automatically Generating AMIs using Puppet

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
more information on each  subcommand by typing `puppet help autoami <subcommand>`

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
  --server <puppet_master> \
  --type <ec2_type> <name_of_group>
```

This may seem like a lot of parameters, but you won't have to specify them again.

Running
-------

To run an instance of all defined groups and check for necessary updates, use
the `puppet autoami run` command.  This will create an instance of each group,
check if puppet changed something, and if so update the AMI.

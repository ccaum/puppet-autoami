# Class: autoupdateami
#
# This module manages automatically updating AMIs
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class autoami( $db_user, $db_password, $db_name = 'autoami', $db_host = 'localhost', $manage_db = false ) {


  $confdir = inline_template("<%= Puppet['confdir'] %>")

  if ! defined(File["${confdir}/scripts"]) {
    file { "${confdir}/scripts":
      ensure => directory,
      mode   => 755,
    }
  }

  file { "${confdir}/scripts/autoami.erb":
    source => 'puppet:///modules/autoami/autoami.erb',
    mode   => 644,
  }

  class { 'autoami::db':
    db_user     => $db_user,
    db_password => $db_password,
    db_name     => $db_name,
  }

  if $manage_db {
    file { '/etc/autoami.conf':
      content => template('autoami/autoami.conf.erb'),
      owner   => root,
      group   => 0,
    }
  }

  if $::puppetversion =~ /Puppet Enterprise/ {
    exec { 'install parseconfig gem':
      command => '/opt/puppet/bin/gem install parseconfig',
      unless  => '/opt/puppet/bin/gem list | grep parseconfig',
    }
  } else {
    include mysql::ruby

    package { 'parseconfig':
      ensure   => installed,
      provider => gem,
    }
  }
}

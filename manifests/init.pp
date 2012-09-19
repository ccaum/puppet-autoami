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
class autoami( $db_user, $db_password, $db_name = 'autoami', $db_host = 'localhost', $manage_db = false) {


  $confdir = inline_template("<%= Puppet['confdir'] %>")

  class { 'autoami::config':
    db_user     => $db_user,
    db_password => $db_password,
    db_name     => $db_name,
    db_host     => $db_host,
  }

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

  if $manage_db {
    class { 'autoami::db':
      db_user     => $db_user,
      db_password => $db_password,
      db_name     => $db_name,
    }
  }
}

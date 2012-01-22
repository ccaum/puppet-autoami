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

}

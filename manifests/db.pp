class autoami::db( $db_user, $db_password, $db_name = 'autoami' ) {
  file { "${autoami::confdir}/autoami.sql":
    source => 'puppet:///modules/autoami/autoami.sql',
    before => Mysql::Db[$db_name],
  }

  mysql::db { $db_name:
    user     => $db_user,
    password => $db_password,
    grant    => all,
    sql      => "${::libdir}/autoami.sql",
  }
}

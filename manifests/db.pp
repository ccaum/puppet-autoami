class autoami::db( $db_user, $db_password, $db_name = 'autoami' ) {
  mysql::db { $db_name:
    user     => $db_user,
    password => $db_password,
    grant    => all,
    sql      => template('autoami/autoami.sql'),
  }
}

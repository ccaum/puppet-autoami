class { 'mysql::server':
  config_hash => {
    'root_password' => 'password'
  },
} ->

class { 'autoami': 
  db_user     => 'autoami',
  db_name     => 'autoami',
  db_password => 'autoami',
  manage_db   => true,
}

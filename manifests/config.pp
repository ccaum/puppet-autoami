class autoami::config( $db_user, $db_password, $db_name = 'autoami', $db_host = 'localhost') {

  $confdir = inline_template("<%= Puppet['confdir'] %>")

  file { "${confdir}/autoami.conf":
    content => template('autoami/autoami.conf.erb'),
    owner   => root,
    group   => 0,
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

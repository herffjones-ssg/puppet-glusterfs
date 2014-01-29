# Class: glusterfs::server
#
# GlusterFS Server.
#
# Parameters:
#  $peers:
#    Array of peer IP addresses to be added. Default: empty
#
# Sample Usage :
#  class { 'glusterfs::server':
#    peers => $::hostname ? {
#      'server1' => '192.168.0.2',
#      'server2' => '192.168.0.1',
#    },
#  }
#
class glusterfs::server (
  $notification_period = "24x7",
  $notification_interval = "30",
  $contact_groups = "indyweb",
  $peers = []
) {

  # Main package and service it provides
  package { 'glusterfs-server': ensure => installed }
  service { 'glusterd':
    enable    => true,
    ensure    => running,
    hasstatus => true,
    require   => Package['glusterfs-server'],
  }

  # Peers
  glusterfs::peer { $peers: }

  file { '/usr/local/bin/gluster_check':
    source => 'puppet:///modules/glusterfs/gluster_check',
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  cron { 'gluster_check_script':
    command => '/usr/local/bin/gluster_check 2>/dev/null',
    user    => 'root',
    minute  => '*/15',
  }

  @@nagios_service { "gluster_check_${::hostname}":
    ensure                => present,
    use                   => "generic-service",
    service_description   => "gluster_check",
    host_name             => $::hostname,
    notification_period   => $notification_period,
    notification_interval => $notification_interval,
    check_command         => "gluster_check",
    contact_groups        => $contact_groups,
    target                => "/etc/nagios/services/${::fqdn}.cfg",
  }

}

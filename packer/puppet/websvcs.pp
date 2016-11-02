node default {
  package { ['unzip','curl','jq','dnsmasq','dnsmasq-base','haproxy']:
    ensure => 'installed',
  }
  class { '::consul':
    config_hash => {
      'data_dir'   => '/opt/consul',
      'datacenter' => 'east-aws',
      'log_level'  => 'INFO',
      'node_name'  => '{{node_name}}',
    }
  }
  ::consul::service { 'websvcs':
    port => 80,
    tags => ['{{node_name}}']
  }
  file { '/etc/dnsmasq.d/consul':
    ensure => 'file',
    source => "file:/tmp/dnsmasq-config",
  }
  class { 'apache': }
}

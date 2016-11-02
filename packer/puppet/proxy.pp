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
  ::consul::service { 'proxy':
    port => 80,
    tags => ['{{node_name}}']
  }
  file { '/etc/dnsmasq.d/consul':
    ensure => 'file',
    source => "file:/tmp/dnsmasq-config",
  }
  class { '::consul_template':
    service_enable   => true,
    log_level        => 'debug',
    init_style       => 'systemd',
    consul_wait      => '5s:30s',
    consul_max_stale => '1s'
  }
}

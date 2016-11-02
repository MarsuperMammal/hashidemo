node 'default' {
  package { ['zip','unzip','curl','jq','dnsmasq','dnsmasq-base']:
    ensure => 'installed',
  }->
  class { '::consul':
    config_hash => {
      'bootstrap_expect' => 3,
      'client_addr'      => '0.0.0.0',
      'data_dir'         => '/opt/consul',
      'datacenter'       => 'east-aws',
      'log_level'        => 'INFO',
      'node_name'        => '{{node_name}}',
      'server'           => true,
      'ui_dir'           => '/opt/consul/ui',
    }
  }->
  file { '/etc/dnsmasq.d/consul':
    ensure => 'file',
    source => "file:/tmp/dnsmasq-consul",
  }
}

node default {
  package { ['unzip','curl','jq','dnsmasq','dnsmasq-base']:
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
  class { '::vault':
    backend => {
      'consul' => {
        'address' => '127.0.0.1:8500',
        'path' => 'vault',
        'advertise_addr' => "https://{{node_name}}.node.consul:8200",
      }
    },
    listener => {
      'tcp' => {
        'address' => '127.0.0.1:8200',
        'tls_disable' => 0,
        'tls_cert_file' => '{{tls_cert_file}}',
        'tls_key_file' => '{{tls_key_file}}',
      }
    }
  }
  ::consul::service { 'vault':
    port => 5200,
    tags => ['{{node_name}}']
  }
  file { '/etc/dnsmasq.d/consul':
    ensure => 'file',
    source => "file:/tmp/dnsmasq-config",
  }
}

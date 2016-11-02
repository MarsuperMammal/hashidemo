#!/bin/bash
set -e
NODE=`curl http://169.254.169.254/latest/meta-data/instance-id`

sed -i -- "s/{{node_name}}/$${NODE}/g" /etc/consul/config.json

cat <<EOF> /etc/consul/atlas.json
{
  "atlas_join": true,
  "atlas_token": "${atlas_token}",
  "atlas_infrastructure": "${atlas_infrastructure}"
}
EOF

service consul restart

#!/bin/bash
set -e
NODE=`curl http://169.254.169.254/latest/meta-data/instance-id`
cat <<EOF> /etc/consul/atlas.json
{
  "atlas_join": true,
  "atlas_token": "${atlas_token}",
  "atlas_infrastructure": "${atlas_infrastructure}"
}
EOF

sed -i -- "s/NODE_NAME/$${NODE}/g" /etc/consul/base.json

service consul restart

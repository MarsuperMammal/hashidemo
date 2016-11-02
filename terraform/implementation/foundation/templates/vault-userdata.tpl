#!/bin/bash
set -e

SSLDIR=/usr/local/etc
SSLCERTPATH=$SSLDIR/vault.crt
SSLKEYPATH=$SSLDIR/vault.key
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

chmod +x /opt/vault/scripts/*

echo "Configuring Consul..."


echo "Updating cert..."

mkdir -p $SSLDIR

echo "${ssl_cert}" | sudo tee $SSLCERTPATH > /dev/null
echo "${ssl_key}" | sudo tee $SSLKEYPATH > /dev/null
chmod -R 0600 $SSLDIR
chown -R vault:vault /usr/local/etc/

cp "$SSLCERTPATH" /usr/local/share/ca-certificates/.
update-ca-certificates

echo "Configuring Vault..."

SSLCERTPATH=$${SSLCERTPATH//\//\\/}
SSLKEYPATH=$${SSLKEYPATH//\//\\/}
sed -i -- "s/{{node_name}}/$${NODE}/g" /etc/vault/config.json
sed -i -- "s/{{tls_cert_file}}/$SSLCERTPATH/g" /etc/vault/config.json
sed -i -- "s/{{tls_key_file}}/$SSLKEYPATH/g" /etc/vault/config.json

cat <<EOF > /lib/systemd/system/vault.service
[Unit]
Description=Vault service
Requires=consul.service
After=network-online.target consul.service

[Service]
User=vault
Group=vault
PrivateDevices=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=read-only
SecureBits=keep-caps
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.json
KillSignal=SIGINT
TimeoutStopSec=30s
Restart=on-failure
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
service vault restart

/opt/vault/scripts/setup_vault.sh

exit 0

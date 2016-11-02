#!/bin/bash
set -e

puppet module install KyleAnderson-consul --version 1.1.0
puppet module install jsok-vault --version 1.1.1
mkdir /opt/vault
mv /tmp/scripts /opt/vault/scripts
mv /tmp/policies /opt/vault/policies
puppet apply /tmp/site.pp

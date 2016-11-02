#!/bin/bash
set -e
wget -O /tmp/puppetlabs-release-pc1-trusty.deb https://apt.puppetlabs.com/puppetlabs-release-pc1-trusty.deb
dpkg -i /tmp/puppetlabs-release-pc1-trusty.deb
apt-get -y update
apt-get -y upgrade
apt-get -y install puppet-agent
ln -s /opt/puppetlabs/bin/puppet /usr/local/bin/puppet

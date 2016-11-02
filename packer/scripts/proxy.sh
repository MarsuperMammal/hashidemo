#!/bin/bash
set -e

puppet module install KyleAnderson-consul --version 1.1.0
puppet module install gdhbashton-consul_template --version 0.2.8

mkdir /etc/consul-template
puppet apply /tmp/site.pp

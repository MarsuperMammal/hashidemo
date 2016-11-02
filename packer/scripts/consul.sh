#!/bin/bash
set -e

puppet module install KyleAnderson-consul --version 1.1.0
puppet apply /tmp/site.pp

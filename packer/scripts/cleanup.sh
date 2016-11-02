#!/bin/bash
set -e

unset HISTFILE
[ -f /root/.bash_history ] && rm /root/.bash_history
echo 'Cleanup log files'
find /var/log -type f | while read f; do echo -ne '' > $f; done;
apt-get -y autoremove
apt-get -y clean
rm -Rf /tmp/*
rm -Rf /var/tmp/*

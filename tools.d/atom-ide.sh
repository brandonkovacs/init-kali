#!/bin/bash

apt -y install libgconf-2-4 gvfs-bin gconf2-common

cd /tmp
wget https://github.com/atom/atom/releases/download/v1.52.0/atom-amd64.deb
dpkg -i atom-amd64.deb 

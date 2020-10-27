#!/bin/bash

cd $REPO_DIR

if [ ! -d "$REPO_DIR/impacket" ]; then
  git clone https://github.com/SecureAuthCorp/impacket.git
fi

cd $REPO_DIR/impacket

pip3 install .

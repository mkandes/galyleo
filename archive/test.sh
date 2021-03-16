#!/usr/bin/env bash

trap "echo '\nITS A TRAP!'" SIGTERM SIGINT

read -p "Would you like to generate the SSH keypair? [y/n]: " -n 1 -r
echo ''
if [[ ! "${REPLY}" =~ ^[Yy]$ ]]; then
  echo 'Use of SSH keys is required.'
  exit 1
else
  echo 'YES!'
fi

#IFS=', ' read -r -a array <<< 

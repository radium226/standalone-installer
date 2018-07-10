#!/bin/bash

export PERSONAL_USER="me"
export PERSONAL_PASSWORD="p4ssw0rd"

export APPLICATIVE_USER="app"

echo " ==> Desinstalling Python"
sudo apt-get -y purge \
  "python3.5" \
  "python3.5-minimal" \
  "python" \
  "python-minimal" \
  "python2.7" \
  "python2.7-minimal"

# https://stackoverflow.com/questions/714915/using-the-passwd-command-from-within-a-shell-script
#echo " ==> Creating Personal User"
#sudo useradd "${PERSONAL_USER}" \
#  --create-home \
#echo "${USER_PASSWORD}:${PERSONAL_PASSWORD}" | sudo chpasswd

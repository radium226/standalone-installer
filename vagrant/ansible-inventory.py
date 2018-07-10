#!/bin/python

# https://medium.com/@megawan/provisioning-vagrant-multi-machines-with-ansible-32e1809816c5

import subprocess as sp
import yaml
import storm as s
import tempfile as tp
from pathlib import Path

def vagrant_ssh_config():
    with tp.NamedTemporaryFile() as ssh_config_file:
        vagrant_process = sp.Popen(["vagrant", "ssh-config"], stdout=sp.PIPE, cwd="../../vagrant")
        stdout = vagrant_process.stdout.read()
        ssh_config_file.write(stdout)
        ssh_config_file.flush()
        config_parser = s.ConfigParser(ssh_config_file.name)
        ssh_config = config_parser.load()
        return ssh_config

def lookup_host(ssh_config, host_name):
    for entry in ssh_config:
        try:
            if entry["host"] == host_name:
                return entry["options"]
        except:
            pass

def ansible_vagrant_config():
    with open("../../vagrant/ansible-vagrant.yml", "r") as f:
        return yaml.load(f)

    ansible_vagrant = yaml.load()
    print(ansible_vagrant)

if __name__ == "__main__":
    ssh_config = vagrant_ssh_config()
    config = ansible_vagrant_config()
    for group_name in config["ansible-groups"]:
        print(f"[{group_name}]")
        for host_name in config["ansible-groups"][group_name]:
            host_ssh_config = lookup_host(ssh_config, host_name)
            ansible_ssh_host = host_ssh_config["hostname"]
            ansible_ssh_port = host_ssh_config["port"]
            ansible_ssh_user = host_ssh_config["user"]
            ansible_ssh_private_key_file = host_ssh_config["identityfile"][0]
            iface = "enp0s8"
            print(f"{host_name} ansible_ssh_host={ansible_ssh_host} ansible_ssh_port={ansible_ssh_port} ansible_ssh_user={ansible_ssh_user} ansible_ssh_private_key_file={ansible_ssh_private_key_file} iface={iface} ansible_python_interpreter=/tmp/installer/pypy/bin/pypy")
        print()

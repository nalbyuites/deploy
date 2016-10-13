#!/bin/bash

# Called for env variables
/root/scripts/vmcontext

touch /root/1.txt
ansible-galaxy install -r /root/scripts/$APP/$APP_requirements.yml
ansible-playbook /etc/ansible/roles/$APP/$APP_playbook.yml
touch /root/2.txt

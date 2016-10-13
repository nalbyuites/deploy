#!/bin/bash -x

APP=`grep APP /tmp/env | cut -d'=' -f2`

ansible-galaxy install -r /root/scripts/$APP/"$APP"_requirements.yml
ansible-playbook /root/scripts/$APP/"$APP"_playbook.yml

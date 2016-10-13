#!/bin/bash

/root/scripts/vmcontext start
APP=`grep APP /tmp/env | cut -d'=' -f2`
/root/scripts/$APP/$APP.sh

rm -f /tmp/env

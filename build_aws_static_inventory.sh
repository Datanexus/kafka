#!/bin/sh

# usage: build_aws_static_inventory.sh
# assumes $key_path is set to the proper directory

# variables that may change
export AWS_PROFILE=datanexus
export AWS=$HOME/.pyenv/shims/aws
ANSIBLE_USER=centos

# variables that shouldn't change
export SED=/usr/bin/sed
export AWK=/usr/bin/awk
export HEAD=/usr/bin/head

# each application should be its own system
applications="zookeeper kafka_broker registry kafka_connect rest_proxy kafka_ksql"
# roles are application vms with dual purpose, eg controlcenter runs on a kafka node
roles="controlcenter"

for app in $applications; do
  echo "[$app]"
  
  # we can get away with taking the first key returned because all applications have the same key
  key=`$AWS ec2 describe-instances --filters "Name=tag:Application,Values=$app" --query 'Reservations[].Instances[].[KeyName,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}' | $HEAD -1 | tr -d '\n'`
  
  for ip in `$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=$app" --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}'`; do
    echo "$ip ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$key_path/aws-$key-private-key.pem"
  done
  echo
done

for role in $roles; do
  echo "[$role]"
  
  # we can get away with taking the first key returned because all applications have the same key
  key=`$AWS ec2 describe-instances --filters "Name=tag:Role,Values=$role" --query 'Reservations[].Instances[].[KeyName,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}' | $HEAD -1 | tr -d '\n'`
  
  for ip in `$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Role,Values=$role" --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}'`; do
    echo "$ip ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$key_path/aws-$key-private-key.pem"
  done
  echo
done
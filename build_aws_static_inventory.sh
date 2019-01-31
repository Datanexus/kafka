#!/bin/sh
#
#
# (c) 2019 Christopher Keller

# usage: build_aws_static_inventory.sh
# assumes $key_path is set to the proper directory

# variables that change per customer
HOSTSFILE=hostsfile            # output file
clusters="none a b"            # only needed if we deal with multiple clusters

# variables that may change
export AWS_PROFILE=datanexus
export AWS=$HOME/.pyenv/shims/aws
ANSIBLE_USER=centos

# variables that shouldn't change
export SED=/usr/bin/sed
export AWK=/usr/bin/awk
export HEAD=/usr/bin/head
export TEE=/usr/bin/tee
export CAT=/bin/cat

# each application should be its own system
applications="shaw zookeeper kafka_broker registry kafka_connect rest_proxy kafka_ksql kafka_replicator elasticsearch"
# roles are application vms with dual purpose, eg controlcenter runs on a kafka node
roles="controlcenter replicator"
# clustered apps
clustered_applications="zookeeper kafka_broker"

# helper function to count list arguments
argc() { argc=$#; }

# just zero out the planned host files; a little inefficient, but it's only done once
for cluster in $clusters; do 
  ip_list=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Cluster,Values=$cluster" --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}'`
  argc $ip_list
  
  if [ $argc -gt 0 ] ; then
    $CAT /dev/null > $HOSTSFILE.$cluster      # zero out the destination file because we use tee in append mode
    $CAT /dev/null > $HOSTSFILE.replication   # zero out the destination file because we use tee in append mode
  fi

done

# parse inventory for every cluster defined; undefined clusters will generate no hosts
for cluster in $clusters; do 

  for app in $applications; do
    
     ip_list=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=$app" "Name=tag:Cluster,Values=$cluster" --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}'`
     argc $ip_list
          
     if [ $argc -gt 0 ] ; then
       echo "[$app]" | $TEE -a $HOSTSFILE.$cluster

       # we can get away with taking the first key returned because all applications have the same key
       key=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=$app" "Name=tag:Cluster,Values=$cluster" --query 'Reservations[].Instances[].[KeyName,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}' | $HEAD -1 | tr -d '\n'`

       for ip in $ip_list; do
         echo "$ip ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$key_path/aws-$key-private-key.pem" | $TEE -a $HOSTSFILE.$cluster
       done
       
       echo | $TEE -a $HOSTSFILE.$cluster
     fi
  done
  
  # the control center node is a broker role
  for role in $roles; do
    
    ip_list=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Role,Values=$role" "Name=tag:Cluster,Values=$cluster" --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}'`
    argc $ip_list
    
    if [ $argc -gt 0 ] ; then
      echo "[$role]" | $TEE -a $HOSTSFILE.$cluster
      # we can get away with taking the first key returned because all applications have the same key
      key=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Role,Values=$role" "Name=tag:Cluster,Values=$cluster" --query 'Reservations[].Instances[].[KeyName,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}' | $HEAD -1 | tr -d '\n'`

      for ip in $ip_list ; do
        echo "$ip ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$key_path/aws-$key-private-key.pem" | $TEE -a $HOSTSFILE.$cluster
      done
      echo | $TEE -a $HOSTSFILE.$cluster
    fi
  done
  
done

# replication
ip_list=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=kafka_replicator" --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}'`
argc $ip_list

if [ $argc -gt 0 ] ; then
  echo "[kafka_replicator]" | $TEE -a $HOSTSFILE.replication
  # we can get away with taking the first key returned because all applications have the same key
  key=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=kafka_replicator"  --query 'Reservations[].Instances[].[KeyName,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}' | $HEAD -1 | tr -d '\n'`

  for ip in $ip_list ; do
    echo "$ip ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$key_path/aws-$key-private-key.pem" | $TEE -a $HOSTSFILE.replication
  done
  echo | $TEE -a $HOSTSFILE.replication
fi

for ca in $clustered_applications; do
  
  ip_list=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=$ca" --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}'`
  argc $ip_list
  
  # if [ $argc -gt 0 ] ; then
#     echo "[$ca]" | $TEE -a $HOSTSFILE.cluster
#     # we can get away with taking the first key returned because all applications have the same key
#     key=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=$ca" --query 'Reservations[].Instances[].[KeyName,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}' | $HEAD -1 | tr -d '\n'`
#
#     for ip in $ip_list ; do
#       echo "$ip ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$key_path/aws-$key-private-key.pem" | $TEE -a $HOSTSFILE.cluster
#     done
#     echo | $TEE -a $HOSTSFILE.cluster
#   fi
  
  for cluster in $clusters; do
    ip_list=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=$ca" "Name=tag:Cluster,Values=$cluster" --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}'`
    argc $ip_list
  
    if [ $argc -gt 0 ] ; then
      echo "[$ca""_$cluster]" | $TEE -a $HOSTSFILE.replication
      # we can get away with taking the first key returned because all applications have the same key
      key=`$AWS ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Application,Values=$ca" "Name=tag:Cluster,Values=$cluster" --query 'Reservations[].Instances[].[KeyName,Tags[?Key==\`Name\`].Value[]]' --output text | $SED '$!N;s/\n/ /' | $AWK '{print $1}' | $HEAD -1 | tr -d '\n'`

      for ip in $ip_list ; do
        echo "$ip ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$key_path/aws-$key-private-key.pem" | $TEE -a $HOSTSFILE.replication
      done
      echo | $TEE -a $HOSTSFILE.replication
    fi
  
  done
  
done

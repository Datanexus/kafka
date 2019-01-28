# confluent platform
This set of playbooks automates the installation, basic configuration, and tuning of the [Confluent platform](https://www.confluent.io/product/confluent-platform/) using either enterprise or community components. It currently does not configure TLS based encryption between nodes, however that functionality is available as part of the [DataNexus platform](https://datanexus.com).

## tl;dr 
Configure the ansible `hostsfile` to resemble your preferred cluster topology, placing the IP address of each node in its respective section. Note that you can co-locate multiple services as long as each node has sufficient memory. 

    # all hosts configured to act as zookeepers
    [zookeeper]
    10.10.1.122 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
    10.10.1.28 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
    10.10.1.32 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

    # all hosts configured to act as kafka brokers
    [kafka_broker]
    10.10.1.142 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
    10.10.1.216 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
    10.10.1.196 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
    10.10.1.13 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

    # all hosts configured to act as schema registries
    [registry]
    10.10.1.154 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

    # all hosts configured to act as distributed connectors
    [kafka_connect]
    10.10.1.252 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

    # all hosts configured to act as rest proxies
    [rest_proxy]
    10.10.1.71 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

    # all hosts configured to act as ksql servers
    [kafka_ksql]
    10.10.1.155 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

    # all hosts configured to act as control center servers (note they must also run kafka brokers)
    [controlcenter]
    10.10.1.13 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

Run the code using the following format:

     ./deploy HOSTSFILE TENANT PROJECT CLOUD REGION DOMAIN CLUSTER 

If deploying on bare metal, every parameter after `HOSTSFILE` is required, but ignored. For AWS, the following is sufficient:

     ./deploy hostsfile datanexus demo aws us-east-1 development none 

## code structure

* `/roles` - the ansible code that does all the work
  * aws - configure AWS only security groups across each node 
  * confluent - configure confluent repos
  * connect - install distributed connector
  * controlcenter - install control center
  * kafka - install kafka brokers
  * kafkarest - install kafka rest service
  * ksql - install ksql
  * preflight - configure cloud only data file systems and hostnames
  * registry - install schema registry
  * zookeeper - install zookeeper
* `/vars`- default variables for each platform component most likely to change across any given installation
* `build_aws_static_inventory.sh` - helper script for generating an ansible hosts file based off meta-data tags (requires AWS CLI)
* `deploy` - simple shell wrapper for calling ansible with CLI variables
* `provision-confluent` - playbook for calling roles in a specific order (entry point into code)

## prerequisites

### ansible server

* ansible version 2.7.5 (slightly older versions will likely work just fine)
*  validated SSH connectivity to each platform node (knowledgable configuration of `.ssh/config` does wonders)

### platform hosts

Minimal node specs:

* 2 VCPUs
* 8 GB RAM
* 10 GB root filesystem
* 10 GB data filesystem

CentOS/RedHat (7+) linux on each node. 

##  aws cloud infrastructure

Easily deploy secure cloud infrastructure using the DataNexus platform. __Remember to zero out any previous jumphosts in ~/.ssh.config__. Application overlay errors are expected since we aren't technically deploying any overlays:

      export key_path=/DataNexus/Demos/infrastructure    
      time groves/orchestrator --keypath $key_path --tenantpath `pwd`/datanexus infrastructure-small-unified.yml directives/confluent.yml
          
## confluent platform 

### variable configuration

The confluent platform consists of seven separate components:

* zookeeper - required
* kafka brokers - required
* schema registry - optional, but usually deployed
* control center - optional
* kafka connect - optional, but usually deployed
* kafka rest - optional
* ksql - optional

If you wish to skip a particular component, simply leave the ansible host group blank. The code will handle the impact of the absense or presence of any particular component across the platform.

The `/vars` subdirectory contains the variables most likely to change per deployment. Reasonable defaults have been chosen.

* `/vars/confluent.yml` - JVM version, confluent platform version 
* `/vars/zookeeper.yml` - data directory for zookeeper 
* `/vars/kafka.yml` - data directory for kafka, default partitions per topic, topic deletion enablement 
* `/vars/registry.yml` - nothing defined
* `/vars/controlcenter.yml` - data directory for control center, location of confluent license (note that confluent grants 30 days usage without a valid file)
* `/vars/connect.yml` - nothing defined
* `/vars/rest.yml` - nothing defined
* `/vars/ksql.yml` - nothing defined

The `/defaults` subdirectory under each ansible role contains variables that generally require more specialized knowledge of the confluent platform before changing, such as TCP ports and JVM memory.

### ansible hosts

Easy generation of a static hosts file is supported within AWS only (this can be run as soon as the VMs are application tagged with the ansible group names):

      ./build_aws_static_inventory.sh | tee hostsfile

Otherwise, configure the ansible `hostsfile` to resemble your preferred cluster topology, placing the IP address of each node in its respective section. Note that you can co-locate multiple services as long as each node has sufficient memory. 

          # all hosts configured to act as zookeepers
          [zookeeper]
          10.10.1.122 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
          10.10.1.28 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
          10.10.1.32 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

          # all hosts configured to act as kafka brokers
          [kafka_broker]
          10.10.1.142 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
          10.10.1.216 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
          10.10.1.196 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
          10.10.1.13 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

          # all hosts configured to act as schema registries
          [registry]
          10.10.1.154 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

          # all hosts configured to act as distributed connectors
          [kafka_connect]
          10.10.1.252 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

          # all hosts configured to act as rest proxies
          [rest_proxy]
          10.10.1.71 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

          # all hosts configured to act as ksql servers
          [kafka_ksql]
          10.10.1.155 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem

          # all hosts configured to act as control center servers (note they must also run kafka brokers)
          [controlcenter]
          10.10.1.13 ansible_user=centos ansible_ssh_private_key_file=./server-key.pem
          
### deployment
Once the ansible `hostsfile` has been generated (either automatically or by hand). Note that the installation is idempotent and multiple runs of the playbook is permissible:

      ./deploy hostsfile datanexus demo aws us-east-1 development none

Once complete, verify the platform is running by port forwarding the control center UI over SSH:

      ssh -i aws-us-east-1-demo-broker-development-private-key.pem 10.10.1.67 -L 9021:localhost:9021

Open a tab in your local browser to [http://localhost:9021](http://localhost:9021).

#### active / passive  cluster

Deploy the source cluster:

    ./deploy hostsfile.a datanexus demo aws us-east-1 development a 

Deploy the destination cluster:

    ./deploy hostsfile.b datanexus demo aws us-east-1 development b
    
Deploy the connect replicator (in this case the replicator is not part of any other cluster):
      
    ./deploy hostsfile.replication datanexus demo aws us-east-1 development none replication
      
### drift
To check for configuration drift from the baseline, the ansible dry run output can be piped through the check wrapper:

    ./deploy hostsfile datanexus demo aws us-east-1 development none drift | ./check

### collect configuration files into /tmp/configuration (set via yaml)

    ./collector -i hostsfile.a
    
  Logs are compressed and can be unarchived with:
    
    tar -zxf ./log.tar.gz
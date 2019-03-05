# 0.1 release 

## installation/upgrade Steps
*       git clone https://github.com/datanexus/kafka.git
*       git clone https://github.com/datanexus/zookeeper.git

## breaking changes
* none

## features
* deploy apache zookeeper and kafka as an overlay on top of aws infrastructure

## fixes
* none

## improvements
* none

## other changes
* none

# 0.1.1 release 

## installation/upgrade Steps
*       git fetch https://github.com/datanexus/kafka.git
*       git merge master
*       git fetch https://github.com/datanexus/zookeeper.git
*       git merge master

## breaking changes
* none

## features
* deploy apache zookeeper and kafka as an overlay on top of openstack infrastructure

## fixes
* none

## improvements
* none

## other changes
* none

# 0.1.2 release 

## installation/upgrade Steps
*       git fetch https://github.com/datanexus/kafka.git
*       git merge master
*       git fetch https://github.com/datanexus/zookeeper.git
*       git merge master

## breaking changes
* none

## features
* none

## fixes
* none

## improvements
* now compatible with ansible 2.4

## other changes
* none

# 0.2 release 

## installation/upgrade Steps
*       git clone https://github.com/datanexus/confluent.git

## breaking changes
* none

## features
* deploy confluent kafka broker and zookeeper packages to all nodes in a cluster using ansible hosts file

## fixes
* none

## improvements
* kakfa and zookeeper are now in a single repository
* support confluent platform commercial and community

## other changes
* none

# 0.3 release 

## installation/upgrade Steps
*       git fetch https://github.com/datanexus/confluent.git
*       git merge master

## breaking changes
* none

## features
* added kafka connect standalone deployment
* added kafka server configuration properties definitions in yaml
* added definition of environments 

## fixes
* fixed issue with minimum number of nodes
* fixed minimum specs for nodes requirement

## improvements
* none

## other changes
* none

# 0.4 release 

## installation/upgrade Steps
*       git fetch https://github.com/datanexus/confluent.git
*       git merge master

## breaking changes
* none

## features
* added kafka streams deployment from yaml
* added support for confluent 4.0+ distribution
* added ksql deployment from yaml
* added control center deployment from yaml
* added schema registry deployment from yaml
* added rest proxy deployment from yaml

## fixes
* fixed minimum specs based on performance tests

## improvements
* none

## other changes
* none

# 0.5 release 

## installation/upgrade Steps
*       git fetch https://github.com/datanexus/confluent.git
*       git merge master

## breaking changes
* none

## features
* added ability to define jvm specs in yaml
* added ability to define kafka/confluent dest practice config items in yaml or take defaults
* added ability to define linux configuration items in yaml or take defaults
  * virtual memory
  * shell
  * kernel
* added ability to test for drift of configuration in linux and Kafka config items as deployed
 
## fixes
* fixed JVM minimum specs

## improvements
* none

## other changes
* none

# 1.0 release 

## installation/upgrade Steps
*       git fetch https://github.com/datanexus/confluent.git
*       git merge master

## breaking changes
* none

## features
* drift rewrite to act realtime instead of at conclusion; provide greater detail on any drifts
* automated computation of JVM heap configuration dynamically based on machine spec
* added kafka worker distributed mode deployment

## fixes
* fixed drift issues

## improvements
* none

## other changes
* none
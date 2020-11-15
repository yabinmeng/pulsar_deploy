# Overview

Apache Pulsar is a distributed messaging and streaming platform. The diagram below shows a typical single-cluster deployment structure for a **Pulsar Instance**. A Pulsar instance can also be deployed having multiple Pulsar clusters that are replicated with each other (aka, geo-replication).

<img src="https://github.com/yabinmeng/pulsar_deploy/blob/master/resources/Pulsar.Architecture.Simplified.jpg" width=800>

The Ansible framework aims to automate the provisioning of a Pulsar instance of the above deployment structure, in particular for the following components:
* A Zookkeeper cluster
* A Bookkeeper cluster
* A Pulsar broker cluster
* A Pulsar manager to manage the Pulsar Instance

* A docker-compose based Prometheus server to scrape metrics from the Pulsar Instance
* A docker-compose based Grafana server to view Pulsar Instance metrics dashboards

# Usage Description

## Testing Environment

The Ansible framework has beene tested in an enviornment with the following specification:

* Ansible version: ***2.10.2***
* Ansible plugin: ***community.general*** (need to be installed first)
```
ansible-galaxy collection install community.general
```
* Remote host OS version: ***Ubuntu*** 16.04.7 LTS 
  **NOTE**: If the remote host has a different OS (e.g. CentOS), the framework needs to be tweaked to reflect OS difference (e.g. apt vs yum)

##  Ansible Playbook

There are 3 Ansible playbooks in this repo., their description is as below:

| Ansible Playbook Name | Description |
| --------------------- | ----------- |
| pulsar_cluster.yaml | Install and configure a Pulsar Instance and all including server components |
| pulsar_mgr_prom.yaml | Install Pulsar manager and docker-compose based Prometheus and Grafana servers |
| shutdown_cluster.yaml | Shut down and clean up the provisioned server components |

The command to exeucte an Ansible playblook is as below:
```
ansible-playbook -i hosts.ini <ansible_playbook.yaml> --private-key=<private_ssh_key> -u <ssh_user>
```

The execution of "shutdown_cluster.yaml" can also take an extra variable which controls whehter or not to delete the downloaded server software binaries.
```
ansible-playbook -i hosts.ini shutdown_cluster.yaml --extra-vars "del_inst=[true|false]" --private-key=<private_ssh_key> -u <ssh_user>
```

### Host Inventory File



### Install and Configure a Pulsar Instance


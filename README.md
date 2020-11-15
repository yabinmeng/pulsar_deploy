# Overview

Apache Pulsar is a distributed messaging and streaming platform. The diagram below shows a typical single-cluster deployment structure for a **Pulsar Instance**. A Pulsar instance can also be deployed having multiple Pulsar clusters that are replicated with each other (aka, geo-replication).

<img src="https://github.com/yabinmeng/pulsar_deploy/blob/master/resources/Pulsar.Architecture.Simplified.jpg" width=800>

The Ansible framework aims to automate the provisioning of a Pulsar instance of the above deployment structure, in particular for the following components:
* A Zookkeeper cluster
* A Bookkeeper cluster
* A Pulsar broker cluster
* A Pulsar manager for Web UI based management of the Pulsar Instance

* A docker-compose based Prometheus server to scrape metrics from the Pulsar Instance
* A docker-compose based Grafana server to view Pulsar Instance metrics dashboards

###  Current Limitation

At the omoment, there are several limitations of the Ansible framework in this repo.:

*  It only supports a single cluster Pulsar instance deployment. It does NOT support deploying a Pulsar instance that has multiple Pulsar clusters.
*  It does NOT have security features enabled such as authentication, authorization, encryption, and etc.

These Ansible framework in this repo. will be improved in the future to lift these limitations.

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

## Host Inventory File Structure

Before running the Ansible playbooks, make sure to create a host inventory file, **hosts.ini**, by copying from the provided template file, **hosts.ini.template**. In the host inventory file, there are 4 groups:

1. **pulsar_cluster_core**

List all Pulsar instance host machines (for zookeepers, bookies, and brokers) under this group. Depending on the actual deployment, one host machines can be configured as being shared by differnt server components. The configuration of having what server components running on one  host machine is conotrolled by the associated Ansible varaiables after each host machine IP, as below:

  * <pulsar_core_server1_ip> **zookeeper**=*[true|false]* **bookie**=*[true|false]* **broker**=*[true|false]*

2. **pulsar_manager**

List the IP of the host machine where Pulsar manager is going to run. One host machine is good enough in this group.

3. **pulsar_metrics**

List the IP of the host machine where Prometheus and Grafana servers are going to run. The Pulsar instance server metrics (zookeepers, bookies, and brokers) can be dispalyed and viewed from Prometheus and Grafana web UIs. One host machine is good enough in this group.

4. **pulsar_clnt**

List all host machines where Pulsar client libraries are needed. Any host machine that runs a Pulsar client application, including those bundled Pulsar command client tools like "pulsar-admin", "pulsar-client", "pulsar-perf", etc., that needs to connect the Pulsar instance falls under this group.

##  Ansible Playbooks

There are 3 Ansible playbooks in this repo., their description is as below:

| Ansible Playbook Name | Description |
| --------------------- | ----------- |
| pulsar_cluster.yaml | Install and configure all server components of a Pulsar Instance |
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

# Pulsar Instance

After successfully executing the Ansible playbook (**pulsar_cluster.yaml**), a Pulsar instance is up and running. On each host machien where one Pulsar instance component server (zookeeper/bookie/broker) is running, 

* A system user is created: **pulsar**
* The Pulsar instance binary is installed in folder: **/opt/pulsar**
* Depending on which server components are running, we should see the following listening ports on the host machine:

| Server Componet | Port | Description |
| --------------- | ---- | ----------- |
| Zookeeper | 2181 | Zookeeper listening port for client connection |  
| Zookeeper | 9990 | The embedded Jetty server port for Zookeeper AdminServer (new in Zookeeper version 3.5.0) |
| Zookeeper | 8000/8010 | Prometheus stats port <br> - 8000: If Zookeeper and bookie are not sharing the same server instance <br> - 8010: If Zookeeper and bookie does share the same server instance |
| Bookie | 8000 | Prometheus stats port |
| Bookie | 3181 | Bookie listening port |
| (Pulsar) Broker | 6550 |  Broker data port |
| (Pulsar) Broker | 6551 |  Broker data port with TLS |
| (Pulsar) Broker | 8080 |  Broker HTTP request service port |
| (Pulsar) Broker | 8443 |  Broker HTTP request service port with TLS |

## Zookeeper



# Pulsar Manager



# Deploy Prometheus and Grafana to Monitor the Pulsar Instance

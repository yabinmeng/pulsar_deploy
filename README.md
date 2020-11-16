- [1. Overview](#1-overview)
  - [1.1. Current Limitation](#11-current-limitation)
- [2. Usage Description](#2-usage-description)
  - [2.1. Testing Environment](#21-testing-environment)
  - [2.2. Host Inventory File Structure](#22-host-inventory-file-structure)
  - [2.3. Ansible Playbooks](#23-ansible-playbooks)
- [3. Pulsar Instance](#3-pulsar-instance)
  - [3.1. Zookeepers](#31-zookeepers)
    - [3.1.1. Zookeeper commands](#311-zookeeper-commands)
    - [3.1.2. Zookeeper AdminServer](#312-zookeeper-adminserver)
    - [3.1.3. Zookeeper Shell](#313-zookeeper-shell)
  - [3.2. Bookies](#32-bookies)
  - [3.3. Brokers](#33-brokers)
- [4. Pulsar Manager](#4-pulsar-manager)
  - [4.1. Pulsar Manager Web UI](#41-pulsar-manager-web-ui)
  - [4.2. Bookkeeper Visual Manager UI](#42-bookkeeper-visual-manager-ui)
- [5. Prometheus and Grafana to Monitor the Pulsar Instance](#5-prometheus-and-grafana-to-monitor-the-pulsar-instance)
  - [5.1. Prometheus Server](#51-prometheus-server)
    - [5.1.1. Prometheus Scraping Endpoints for the Pulsar Instance](#511-prometheus-scraping-endpoints-for-the-pulsar-instance)
    - [5.1.2. Prometheus Web UI](#512-prometheus-web-ui)
  - [5.2. Grafana Server](#52-grafana-server)
    - [5.2.1. Grafana WebUI](#521-grafana-webui)
    - [5.2.2. Predefined Dashboard for the Pulsar Instance](#522-predefined-dashboard-for-the-pulsar-instance)
- [6. Appendex A: Pulsar Connectors](#6-appendex-a-pulsar-connectors)
- [7. Appendix B: Pulsar-perf](#7-appendix-b-pulsar-perf)


# 1. Overview

Apache Pulsar is a distributed messaging and streaming platform. The diagram below shows a typical single-cluster deployment structure for a **Pulsar Instance**. A Pulsar instance can also be deployed having multiple Pulsar clusters that are replicated with each other (aka, geo-replication).

<img src="https://github.com/yabinmeng/pulsar_deploy/blob/master/resources/Pulsar.Architecture.Simplified.jpg" width=800>

The Ansible framework aims to automate the provisioning of a Pulsar instance of the above deployment structure, in particular for the following components:
* A Zookeeper cluster
* A Bookkeeper cluster
* A Pulsar broker cluster
* A Pulsar manager for Web UI based management of the Pulsar Instance

* A docker-compose based Prometheus server to scrape metrics from the Pulsar Instance
* A docker-compose based Grafana server to view Pulsar Instance metrics dashboards

##  1.1. Current Limitation

At the omoment, there are several limitations of the Ansible framework in this repo.:

*  It only supports a single cluster Pulsar instance deployment. It does NOT support deploying a Pulsar instance that has multiple Pulsar clusters.
*  It does NOT have security features enabled such as authentication, authorization, encryption, and etc.

These Ansible framework in this repo. will be improved in the future to lift these limitations.

# 2. Usage Description

## 2.1. Testing Environment

The Ansible framework has beene tested in an enviornment with the following specification:

* Ansible version: ***2.10.2***
* Ansible plugin: ***community.general*** (need to be installed first)
```
ansible-galaxy collection install community.general
```
* Remote host OS version: ***Ubuntu*** 16.04.7 LTS 
  **NOTE**: If the remote host has a different OS (e.g. CentOS), the framework needs to be tweaked to reflect OS difference (e.g. apt vs yum)
* Apache Pulsar version: ***2.6.1*** (configurable)

## 2.2. Host Inventory File Structure

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

##  2.3. Ansible Playbooks

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

# 3. Pulsar Instance

After successfully executing the Ansible playbook (**pulsar_cluster.yaml**), a Pulsar instance is up and running. On each host machien where one Pulsar instance component server (zookeeper/bookie/broker) is running, 

* A system user is created: **pulsar**
* The Pulsar instance binary (for all server components) is installed in folder: **/opt/pulsar**
* Depending on which server components are running, we should see the following listening ports on the host machine:

| Server Componet | Port | Ansible Variable | Description |
| --------------- | ---- | ---------------- | ----------- |
| Zookeeper | 2181 | zk_clnt_port | Zookeeper listening port for client connection |  
| Zookeeper | 9990 | zk_admin_srv_port | The embedded Jetty server port for Zookeeper AdminServer (new in Zookeeper version 3.5.0) |
| Zookeeper | 8000/8010 | zk_stats_port | Prometheus stats port <br> - 8000: If Zookeeper and bookie are not sharing the same server instance <br> - 8010: If Zookeeper and bookie does share the same server instance |
| Bookie | 8000 | bk_stats_port | Prometheus stats port |
| Bookie | 3181 | bookie_listening_port | Bookie listening port |
| (Pulsar) Broker | 6550 | broker_svc_port | Broker data port |
| (Pulsar) Broker | 6551 | broker_svc_port_tls | Broker data port with TLS |
| (Pulsar) Broker | 8080 | web_svc_port | HTTP request service port <br> It also servers as Prometheus stats port |
| (Pulsar) Broker | 8443 | web_svc_port | Broker HTTP request service port with TLS |

**NOTE**: all the above ports are configurable through Ansible variables.

---

The main configuration files for the various Pulsar instance compoents are under folder: **/opt/pulsar/conf**. The configuration files that are touched by this playbook are the following ones:
* zookeeper.conf
* bookkeeper.conf
* broker.conf
* client.conf

## 3.1. Zookeepers

### 3.1.1. Zookeeper commands

In this playbook, all [Zookeeper "four-letter-words (4lw)" commands](https://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_zkCommands) and  white list is enabled through the following configuration:
```
4lw.commands.whitelist=*
```

From any server host machine where Zookeeper is running, we can run these 4lw commands on the command line to get the Zookeeper server information. An example is as below:
```
$ echo srvr | nc localhost 2181
Zookeeper version: 3.5.7-f0fdd52973d373ffd9c86b81d99842dc2c7f660e, built on 02/10/2020 11:30 GMT
Latency min/avg/max: 0/0/22
Received: 2969
Sent: 2996
Connections: 5
Outstanding: 0
Zxid: 0x100000108
Mode: follower
Node count: 105
```

### 3.1.2. Zookeeper AdminServer

For Zookeeper version 3.5.0+, it includes an embedded Jetty server that provides a simple HTTP interface to Zookeeper's 4lw commands. For Pulsar 2.6.1 (as tested using this repo.), the corresponding Zookeeper version is 3.5.7 and therefore Zookeeper AdminServer is available and enabled by default at port 9990. In order to access Zookeeper AdminServer WebUI, access the following address:

```
http://<zookeeper_node_ip>:9990/commands
```

### 3.1.3. Zookeeper Shell

We can also launch a Zookeeper shell to check or set the Pulsar instance related metadata that is stored in the zookeeper. 

```
$ sudo -u pulsar pulsar zookeeper-shell
Connecting to localhost:2181
21:10:34.395 [main] INFO  org.apache.zookeeper.ZooKeeper - Client environment:zookeeper.version=3.5.7-f0fdd52973d373ffd9c86b81d99842dc2c7f660e, built on 02/10/2020 11:30 GMT
... ...
WATCHER::

WatchedEvent state:SyncConnected type:None path:null

```

For Zookeeper shell commands, please refer to Zookeeper document [here](https://zookeeper.apache.org/doc/r3.6.0/zookeeperCLI.html)

## 3.2. Bookies

## 3.3. Brokers

# 4. Pulsar Manager 

Pulsar manager is a web-based utility tool to help managing and monitor a Pulsar instance, such  as enants, namespaces, topics, subscriptions, brokers, clusters, and so on. [Pulsar manager](https://pulsar.apache.org/docs/en/administration-pulsar-manager/) replaces the old, depercated Pulsar Dashboard. Pulsar manager is not part of standar Pulsar package. It can be downloaded from [here](https://github.com/apache/pulsar-manager). 

Part of the Ansible playbook (**pulsar_mgr_prom.yaml**) is responsible for installing and configuring a Pulsar manager on the specified host machine. The Pulsar manager binaries are located under folder: **/opt/pulsar-manager**.

If running successfully, the following Pulsar manager listens on the following port:

| Port | Ansible Variable | Description |
| ---- | ---------------- | ----------- |
| 7750 | pulsar_mgr_webui_port | Pulsar manager backend service listening port |

**NOTE** for production deployment, there are more listening ports that can be configured with Pulsar manager; but it is beyond the scope of this document.

## 4.1. Pulsar Manager Web UI

One Pulsar manager is able to monitor multiple Pulsar instance. In Pulsar manager, one Pulsar instance is called an **Environment**. In order to access the Pulsar manager web UI, use the following URL:

```
http://<pulsar_manager_host_ip>:7750/ui/index.html
```

When prompted to enter user name and password, enter **pulsar**/**pulsar**. This adminstrative username and passowrd is created as part of running this playbook. Once logged in, Click "+ New Environment" button to add a Pulsar instance to manage. An example UI is as below (the managed Pulsar instance name is "mypulsar_instance")

<img src="https://github.com/yabinmeng/pulsar_deploy/blob/master/resources/Pulsar.Manager.Topics.jpg" width=800>

## 4.2. Bookkeeper Visual Manager UI

Pulsar Manager also has a Web UI as **Bookkeeper Visual Manager**. You can access it from the following URL:

```
http://<pulsar_manager_host_ip>:7750/bkvm
```

When prompted to enter user name and password, enter **admin**/**admin**

# 5. Prometheus and Grafana to Monitor the Pulsar Instance

Another part of the Ansible playbook (**pulsar_mgr_prom.yaml**) is to lauch docker containers, via docker-compose, on the specified host machine in order to view the metrics for the provisioned Pulsar instance. The Pulsar metrics binaries are located under folder: **/opt/pulsar-metrics**.

If running successfully, there are 3 launched containers with the following externally exposed ports:

| Container Name | Externally Exposed Port |
| -------------- | ----------------------- |
| prometheus | 9090 |
| grafana | 3000 |
| graphite-exporter | 9108 (TCP)<br>9109 (UDP) |

## 5.1. Prometheus Server

### 5.1.1. Prometheus Scraping Endpoints for the Pulsar Instance

Within a Pulsar instance, all server components (zookeepers, bookies, and brokers) expose their metrics in Prometheus format. Their corresponding Prometheus scraping HTTP endpoints are listed as below:

| Server Component | Prometheus Scraping Endpoints |
| ---------------- | ----------------------------- |
| zookeeper | <zookeeper_node_ip>:8000/metrics (If zookeeper and bookie are not are the same host machine)<br><zookeeper_node_ip>:8010/metrics (If zookeeper and bookie does share the same host machine) |
| bookie | <bookie_node_ip>:8000/metrics |
| broker | <broker_node_ip>:8080/metrics |

The Ansible playbook will automatically configure the Prometheus server to pick up the scraping endpoints for all server components within a Pulsar instance.

### 5.1.2. Prometheus Web UI

Once Prometheus server is successfully up and running, we can view the available metrics for all Pulsar instance server components from Prometheus Targets web page at the following URL (followed by an example screenshot)

```
http://<pulsar_metrics_host_ip>:9090/targets
```

<img src="https://github.com/yabinmeng/pulsar_deploy/blob/master/resources/Prometheus.Targets.jpg" width=800>

## 5.2. Grafana Server

### 5.2.1. Grafana WebUI

### 5.2.2. Predefined Dashboard for the Pulsar Instance

# 6. Appendex A: Pulsar Connectors

# 7. Appendix B: Pulsar-perf
- [1. Overview](#1-overview)
  - [1.1. Current Limitation](#11-current-limitation)
- [2. Usage Description](#2-usage-description)
  - [2.1. Testing Environment](#21-testing-environment)
  - [2.2. Host Inventory File Structure](#22-host-inventory-file-structure)
  - [2.3. Ansible Playbooks](#23-ansible-playbooks)
- [3. Pulsar Instance](#3-pulsar-instance)
  - [3.1. Deployment Overview](#31-deployment-overview)
  - [3.2. Zookeepers](#32-zookeepers)
    - [3.2.1. Zookeeper commands](#321-zookeeper-commands)
    - [3.2.2. Zookeeper AdminServer](#322-zookeeper-adminserver)
    - [3.2.3. Zookeeper Shell](#323-zookeeper-shell)
  - [3.3. Bookies](#33-bookies)
    - [3.3.1. Bookkeeper Shell Commands](#331-bookkeeper-shell-commands)
  - [3.4. Brokers](#34-brokers)
- [4. Pulsar Manager](#4-pulsar-manager)
  - [4.1. Pulsar Manager Web UI](#41-pulsar-manager-web-ui)
  - [4.2. Bookkeeper Visual Manager UI](#42-bookkeeper-visual-manager-ui)
- [5. Prometheus and Grafana to Monitor the Pulsar Instance](#5-prometheus-and-grafana-to-monitor-the-pulsar-instance)
  - [5.1. Prometheus Server](#51-prometheus-server)
    - [5.1.1. Prometheus Scraping Endpoints for the Pulsar Instance](#511-prometheus-scraping-endpoints-for-the-pulsar-instance)
    - [5.1.2. Prometheus Web UI](#512-prometheus-web-ui)
  - [5.2. Grafana Server](#52-grafana-server)
    - [5.2.1. Grafana WebUI and Data Source](#521-grafana-webui-and-data-source)
    - [5.2.2. Predefined Dashboard for the Pulsar Instance](#522-predefined-dashboard-for-the-pulsar-instance)
- [6. Appendix A: Pulsar Connectors and Tiered Storage Offloaders](#6-appendix-a-pulsar-connectors-and-tiered-storage-offloaders)
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

At the moment, there are several limitations of the Ansible framework in this repo.:

1. It only supports a single cluster Pulsar instance deployment. It does NOT support deploying a Pulsar instance that has multiple Pulsar clusters.
2. It doesn't yet have security features enabled such as authentication, authorization, encryption, and etc.
3. Although the tiered storage offloading enablement is supported, the actual implementation mechanism (e.g. S3, GCS, or filesystem) is not in place yet.
4. It doesn't support the deployment of Pulsar proxy yet. For production deployment and/or for security purposes, a proxy based Pulsar instance deployment is preferred.

This Ansible framework in this repo. will be improved in the future to lift these limitations.

# 2. Usage Description

## 2.1. Testing Environment

The Ansible framework has been tested in an environment with the following specification:

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

List all Pulsar instance host machines (for zookeepers, bookies, and brokers) under this group. Depending on the actual deployment, one host machine can be configured as being shared by different server components. The configuration of having what server components running on one  host machine is controlled by the associated Ansible variables after the IP address of each host machine, as below:

  * <pulsar_core_server1_ip> **zookeeper**=*[true|false]* **bookie**=*[true|false]* **broker**=*[true|false]*

This group can be part of **pulsar_clnt** group.

2. **pulsar_manager**

List the IP address of the host machine where Pulsar manager is going to run. One host machine is good enough in this group. 

This group needs to be part of **pulsar_clnt** group.

3. **pulsar_perf**

List IP addresses of all host machines where we need to run Pulsar-perf utility (for performance testing purposes). 

This group needs to be part of **pulsar_clnt** group.

4. **pulsar_clnt**

List IP addresses of all host machines where Pulsar client libraries are needed. Any host machine that runs a Pulsar client application, including those bundled Pulsar command client tools like "pulsar-admin", "pulsar-client", "pulsar-perf", etc., that needs to connect the Pulsar instance falls under this group.

5. **pulsar_metrics**

List the IP address of the host machine where Prometheus and Grafana servers are runniing. The Pulsar instance server metrics (zookeepers, bookies, and brokers) will be displayed and viewed from Prometheus and Grafana web UIs.

This group doesn't need to be part of **pulsar_clnt** group.

##  2.3. Ansible Playbooks

There are 3 Ansible playbooks in this repo., their description is as below:

| Ansible Playbook Name | Description |
| --------------------- | ----------- |
| pulsar_cluster.yaml | Install and configure all server components of a Pulsar Instance |
| pulsar_mgr_prom.yaml | Install Pulsar manager and docker-compose based Prometheus and Grafana servers |
| shutdown_cluster.yaml | Shut down and clean up the provisioned server components |

The command to execute an Ansible playbook is as below:
```
ansible-playbook -i hosts.ini <ansible_playbook.yaml> --private-key=<private_ssh_key> -u <ssh_user>
```

The execution of "shutdown_cluster.yaml" can also take an extra variable which controls whether or not to delete the downloaded server software binaries.
```
ansible-playbook -i hosts.ini shutdown_cluster.yaml --extra-vars "del_inst=[true|false]" --private-key=<private_ssh_key> -u <ssh_user>
```

# 3. Pulsar Instance

After successfully executing the Ansible playbook (**pulsar_cluster.yaml**), a Pulsar instance is up and running. On each host machine where one Pulsar instance component server (zookeeper/bookie/broker) is running, 

* A system user is created: **pulsar**
* The Pulsar instance binary (for all server components) is installed in folder: **/opt/pulsar**
* Depending on which server components are running, we should see the following listening ports on the host machine:

| Server Component | Port | Ansible Variable | Description |
| ---------------- | ---- | ---------------- | ----------- |
| Zookeeper | 2181 | zk_clnt_port | Zookeeper listening port for client connection |  
| Zookeeper | 9990 | zk_admin_srv_port | The embedded Jetty server port for Zookeeper AdminServer (new in Zookeeper version 3.5.0) |
| Zookeeper | 8000/8010 | zk_stats_port | Prometheus stats port <br> - 8000: If Zookeeper and bookie are not sharing the same server instance <br> - 8010: If Zookeeper and bookie does share the same server instance |
| Bookie | 8000 | bk_stats_port | Prometheus stats port |
| Bookie | 3181 | bookie_listening_port | Bookie listening port |
| (Pulsar) Broker | 6550 | broker_svc_port | Broker data port |
| (Pulsar) Broker | 6551 | broker_svc_port_tls | Broker data port with TLS |
| (Pulsar) Broker | 8080 | web_svc_port | HTTP request service port <br> It also servers as Prometheus stats port |
| (Pulsar) Broker | 8443 | web_svc_port_tls | Broker HTTP request service port with TLS |

**NOTE**: all the above ports are configurable through Ansible variables.

---

The main configuration files for the various Pulsar instance components are under folder: **/opt/pulsar/conf**. The configuration files that are modified by this playbook are the following ones:
* zookeeper.conf
* bookkeeper.conf
* broker.conf
* client.conf

## 3.1. Deployment Overview

The overall Pulsar instance deployment sequence using this framework is as below:

1. Download and install Pulsar binaries
2. Make necessary configuration file changes based on server component types (zookeepers, bookies, and brokers)
3. Start Zookeeper cluster (in sequence) and wait to verify all zookeeper servers are up and running
   1. Initialize Pulsar cluster metadata
4. Start Bookkeeper cluster (in sequence) and wait to verify all bookie servers are up and running
5. Start Broker cluster (in sequence) and wait to verify all broker servers are up and running

## 3.2. Zookeepers

### 3.2.1. Zookeeper commands

In this playbook, the [Zookeeper "four-letter-words (4lw)" command](https://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_zkCommands) can be enabled via the following Ansible variables. By default, when enabled, all Zookeeper 4lw commands are allowed. If only specific commands are needed, please change the white list setting accordingly (individual commands separated by comma, e.g. ruok, stat)

```
4lw_enabled: true
4lw_white_list: *
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

### 3.2.2. Zookeeper AdminServer

For Zookeeper version 3.5.0+, it includes an embedded Jetty server that provides a simple HTTP interface to Zookeeper's 4lw commands. For Pulsar 2.6.1 (as tested using this repo.), the corresponding Zookeeper version is 3.5.7 and therefore Zookeeper AdminServer is available and enabled by default at port 9990. In order to access Zookeeper AdminServer WebUI, access the following address:

```
http://<zookeeper_node_ip>:9990/commands
```

### 3.2.3. Zookeeper Shell

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

## 3.3. Bookies

After each bookie server is up and running (e.g., port 3181 is in listening state), the playbook also does a quick sanity check for the bookie, using the following bookkeeper's shell command. The failure of this command will trigger an error and therefore stop the execution of the playbook.

```
$ bookkeeper shell bookiesanity
```

### 3.3.1. Bookkeeper Shell Commands

There are many other bookkeeper shell commands that can be used to view and manage the bookies. For example, we can use the following command to get the free space of each bookie:

```
$ bookkeeper shell bookieinfo
... ...
Free disk space info:
<bookie_ip_1>(<bookie_hostname_1>):3181:	Free: 35576426496(35.576GB)	Total: 40193699840(40.193GB)
<bookie_ip_2>(<bookie_hostname_2>):3181:	Free: 35544129536(35.544GB)	Total: 40193699840(40.193GB)
<bookie_ip_3>(<bookie_hostname_3>):3181:	Free: 35467866112(35.467GB)	Total: 40193699840(40.193GB)
Total free disk space in the cluster:	106588422144(106.588GB)
Total disk capacity in the cluster:	120581099520(120.581GB)
... ... 
```

**NOTE**: for a full list of bookkeeper shell commands, please refer to Bookkeeper document [here](https://bookkeeper.apache.org/docs/4.5.1/reference/cli/#the-bookkeeper-shell)

## 3.4. Brokers

After each broker server is up and running (e.g., ports 6550/6551/8080/8443 are in listening state), we can test writing(producing)/reading(consuming) messages to/from any broker using the included **pulsar-client** utility. 

In order to run any Pulsar client application, including **pulsar-client** utility, it needs to be configured first in order to make sure the proper web service and broker service URL are known to the client. The client configuration file is **client.conf** file and the playbook updates it properly on any host machines under Ansible **pulsar_clnt** group.

The following command can be used to test producing a message to a broker:

```
$ sudo -u pulsar pulsar-client produce \
  persistent://public/default/test \
  -n 1 \
  -m "Hello Pulsar"
```

The following command can be used to test consuming a message from a broker (in exclusive mode):

```
$ sudo -u pulsar pulsar-client consume \
  persistent://public/default/test \
  -n 100 \
  -s "consumer-test" \
  -t "Exclusive"
```

# 4. Pulsar Manager 

Pulsar manager is a web-based utility tool to help manage and monitor a Pulsar instance, such  as tenants, namespaces, topics, subscriptions, brokers, clusters, and so on. [Pulsar manager](https://pulsar.apache.org/docs/en/administration-pulsar-manager/) replaces the old, deprecated Pulsar Dashboard. Pulsar manager is not part of standar Pulsar package. It can be downloaded from [here](https://github.com/apache/pulsar-manager). 

Part of the Ansible playbook (**pulsar_mgr_prom.yaml**) is responsible for installing and configuring a Pulsar manager on the specified host machine. The Pulsar manager binaries are located under folder: **/opt/pulsar-manager**.

If running successfully, the following Pulsar manager listens on the following port:

| Port | Ansible Variable | Description |
| ---- | ---------------- | ----------- |
| 7750 | pulsar_mgr_webui_port | Pulsar manager backend service listening port |

**NOTE** for production deployment, there are more listening ports that can be configured with Pulsar manager; but it is beyond the scope of this document.

## 4.1. Pulsar Manager Web UI

One Pulsar manager is able to monitor multiple Pulsar instances. In Pulsar manager, one Pulsar instance is called an **Environment**. In order to access the Pulsar manager web UI, use the following URL:

```
http://<pulsar_manager_host_ip>:7750/ui/index.html
```

When prompted to enter user name and password, enter **pulsar**/**pulsar**. This administrative username and password is created as part of running this playbook. Once logged in, Click "+ New Environment" button to add a Pulsar instance to manage. An example UI is as below (the managed Pulsar instance name is "mypulsar_instance")

<img src="https://github.com/yabinmeng/pulsar_deploy/blob/master/resources/Pulsar.Manager.Topics.jpg" width=800>

## 4.2. Bookkeeper Visual Manager UI

Pulsar Manager also has a Web UI as **Bookkeeper Visual Manager**. You can access it from the following URL:

```
http://<pulsar_manager_host_ip>:7750/bkvm
```

When prompted to enter user name and password, enter **admin**/**admin**

# 5. Prometheus and Grafana to Monitor the Pulsar Instance

Another part of the Ansible playbook (**pulsar_mgr_prom.yaml**) is to launch docker containers, via docker-compose, on the specified host machine in order to view the metrics for the provisioned Pulsar instance. The Pulsar metrics binaries are located under folder: **/opt/pulsar-metrics**.

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

### 5.2.1. Grafana WebUI and Data Source

The Grafana dashboard web UI can be accessed from the following URL:

```
http://<pulsar_metrics_host_ip>:3000
```

Once prompted for username and password, enter **admin/admin**. Since all metrics for the Pulsar instance are scraped into the Prometheus server that resides on the same host machine, the playbook defines one and the only one Grafana data source with the following info:

* Name: **prometheus**
* HTTP URL: **http://prometheus:9090**

All other data source configuration remains default.

### 5.2.2. Predefined Dashboard for the Pulsar Instance

**=== TBD ===**

# 6. Appendix A: Pulsar Connectors and Tiered Storage Offloaders

This Ansible framework provides support for Pulsar connectors through the following Ansible variables. Currently for testing purposes, 2 source connectors (file and netty) and 1 sink connector (Cassandra) are enabled. If more connectors, please add them accordingly in the list. 

```
builtin_connector: true
pulsar_connectors:
  # Source connectors
  - file
  - netty
  # Sink connectors
  - cassandra
```

For more information about Pulsar built-in connectors, please check Pulsar documents: [source connector](https://pulsar.apache.org/docs/en/io-connectors/#source-connector) and [sink connector](https://pulsar.apache.org/docs/en/io-connectors/#sink-connector)

Similarly, the framework also enables the capability of using tiered storage by the following Ansible variable. **NOTE** however, the actual implementation of using a specific tiered storage offloading mechanism (e.g. S3, GCS, filesystem, etc.) is NOT in place yet.

```
tierstorage_offloader: true
```

# 7. Appendix B: Pulsar-perf

[Pulsar perf](https://pulsar.apache.org/docs/en/performance-pulsar-perf/) is a built-in performance test tool for Apache Pulsar. It can be used to test both producing and consuming messages. It provides a good amount of options to control the performance testing behavior such as:

* the number of test threads
* the number of producers/consumers for each topic
* the number of topics
* the maximum number of TCP connections per single broker
* the maximum rate of producing/consuming messages across topics
* message size and payload
* ... ... 

By default, Pulsar perf uses "**client.conf**" as the default configuration file. Therefore, in this repo, we can run Pulsar-perf against the provisioned Pulsar instance on any host machines under group **pulsar_clnt** (hosts.ini). This includes the host machine where we install Pulsar manager and all host machines within the Pulsar instance. 

If a dedicated performance testing machine is preferred to run Pulsar-perf, we can use a dedicate Ansible group (e.g. **pulsar_perf**) in the host inventory file and make sure to make it as a child of **pulsar_clnt** group, something like below (as in this Ansible framework)

```
... ...

[pulsar_perf]
<pulsar_perf_host_ip>>

[pulsar_clnt:children]
pulsar_cluster_core
pulsar_manager
pulsar_perf

... ...
```
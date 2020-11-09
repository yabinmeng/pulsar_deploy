
# The local directory where the SSH key files are stored
#
variable "ssh_key_localpath" {
   default = "/Users/yabinmeng/.ssh"
}

#
# The local private SSH key file name 
#
variable "ssh_key_filename" {
   default = "id_rsa_aws"
}

#
# AWS EC2 key-pair name
#
variable "keyname" {
   default = "dse-sshkey"
}

#
# Default AWS region
#
variable "region" {
   //default = "us-east-1"
   default = "us-east-2"
}

#
# Default OS image: Ubuntu
#
variable "ami_id" {
   # Ubuntu Server 16.04 LTS (HVM), SSD Volume Type
   // us-east-1
   #default = "ami-10547475"
   # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type (64-bit x86)
   // us-east-1
   //default = "ami-0bcc094591f354be2"
   // us-east-2
   default = "ami-0e82959d4ed12de3f"
}

#
# AWS resource tag identifier
#
variable "tag_identifier" {
   default = "ymtest"
} 

#
# Environment description
#
variable "env" {
   default = "automation_test"
}

#
# EC2 instance type 
#
# Zookeeper server type
variable "zk_srv_type" {
   default = "zk_srv"
}
# Bookkeeper server type
variable "bk_srv_type" {
   default = "bk_srv"
}
# Pulsar broker type
variable "pulsar_broker_type" {
   default = "pulsar_broker"
}

variable "instance_count" {
   type = map
   default = {
      zk_srv        = 0
      bk_srv        = 0
      pulsar_broker = 3
   }
}

variable "instance_type" {
   type = map
   default = {
      zk_srv        = "a1.xlarge"
      bk_srv        = "a1.2xlarge"
      pulsar_broker = "a1.4xlarge"
   }
}
# Copyright (c) 2021 Oracle and/or its affiliates.

variable "tenancy_ocid" {
  description = "OCI tenant OCID, more details can be found at https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five"
}
variable "region_1" {
  description = "OCI Region as documented at https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm"
  default = "us-phoenix-1"
}
variable "region_2" {
  description = "OCI Region as documented at https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm"
  default = "us-ashburn-1"
}
variable "compartment_ocid" {
  default = ""
  description = "The compartment OCID to deploy resources to"
}
variable "user_ocid" {
  default = ""
  description = "OCI user OCID, more details can be found at https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five"
}
variable "fingerprint" {
  default = ""
  description = "'API Key' fingerprint, more details can be found at https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/credentials.htm#two"
}
variable "private_key" {
  default = ""
  description = "The private key (provided as a string value)"
}
variable "private_key_path" {
  default = ""
  description = "Path to private key used to create OCI 'API Key', more details can be found at https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/credentials.htm#two"
}
variable "private_key_password" {
  default = ""
  description = "The password to use for the private key"
}
# see https://docs.oracle.com/en-us/iaas/images/ for image names
variable "compute_image_name" {
  description = "The name of the compute image to use for the compute instances."
}
variable "ssh_pub_key_path" {
  type = string
  default = ""
  description = "The path to the SSH public key to use for the compute instances."
}
variable "ssh_pub_key" {
  type = string
  default = ""
  description = "The SSH public key contents to use for the compute instances."
}

variable "ssh_priv_key_path" {
  type = string
  default = ""
  description = "The path to the private key used for SSH connections."
}

variable "ssh_priv_key" {
  type = string
  default = ""
  description = "The contents of the private key used for SSH connections."
}

variable "num_web_svrs" {
  type = number
  default = 2
  description = "The number of web servers to deploy in each region."
}

variable "num_consul_svrs" {
  type = number
  default = 3
  description = "The number of Consul servers to deploy in each region."
}

variable "lb_priv_key" {
  type = string
  default = "lb.key"
  description = "The file name of the private key to use for the LB."
}

variable "lb_pub_key" {
  type = string
  default = "lb.crt"
  description = "The file name of the public key to use for the LB."
}

variable "my_public_ip" {
  type = string
  description = "The public IP address of your machine (what is permitted to talk to the LB listener)."
}
variable "vsphere_user" {
    type = string
}
variable "vsphere_password" {
    type = string
}
variable "vsphere_server" {
    type = string
}
variable "allow_unverified_ssl" {
    type = bool
}

provider "vsphere" {
  user			= var.vsphere_user
  password		= var.vsphere_password
  vsphere_server	= var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl
  version = "~> 1.18"
}

variable "networks" {
  type = list(string)
}

variable "templates" {
  type = list(string)
}

variable "datastores" {
  type = list(string)
}

data "vsphere_datacenter" "dc" {
  name = "ha-datacenter"
}

data "vsphere_compute_cluster" "ha-cluster" {
  name = "ha-cluster"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "all" {
  count = length(var.datastores)

  name = var.datastores[count.index]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_distributed_virtual_switch" "dvs1" {
  name          = "dvs1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "all" {
  count = length(var.networks)

  name          = var.networks[count.index]
  datacenter_id = data.vsphere_datacenter.dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs1.id
}

data "vsphere_virtual_machine" "templates" {
  count = length(var.templates)

  name = var.templates[count.index]
  datacenter_id = data.vsphere_datacenter.dc.id
}

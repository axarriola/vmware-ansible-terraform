variable "_meta" {
    type = map
}

resource "vsphere_virtual_machine" "vsphere_vms" {
  for_each = var._meta.hostvars

  name = each.key
  resource_pool_id = data.vsphere_compute_cluster.ha-cluster.resource_pool_id
  #datastore is defined for each disk
  #datastore_id	= data.vsphere_datastore.all.0.id

  num_cpus = each.value.guest_vcpu
  memory = each.value.guest_memory
  guest_id = [ for i in data.vsphere_virtual_machine.templates : i.guest_id if i.name == each.value.guest_template ][0]
  scsi_type	= [ for i in data.vsphere_virtual_machine.templates : i.scsi_type if i.name == each.value.guest_template ][0]
  firmware	= "bios"

  dynamic "network_interface" {
    for_each = each.value.network_adapters

    content {
      network_id          = [ for i in data.vsphere_network.all : i.id if i.name == network_interface.value.name ][0]
      adapter_type        = "vmxnet3"
    }
  }

  dynamic "disk" {
    for_each = each.value.disk_layout

    content {
      label = "disk${disk.key}"
      datastore_id = [ for i in data.vsphere_datastore.all : i.id if i.name == disk.value.datastore ][0]
      size = disk.value.size_gb
      thin_provisioned = disk.value.type == "thin" ? true : false
    } 
  }

  clone {
    template_uuid 	= data.vsphere_virtual_machine.templates.0.id
    customize {
      linux_options {
        host_name	= each.key
        domain		= "mydomain.com"
      }

      dynamic "network_interface" {
        for_each = each.value.network_adapters

        content {
          ipv4_address      = network_interface.value.ip
          ipv4_netmask      = "24" #tonumber(network_interface.value.netmask)
          ipv6_address      = network_interface.value.ipv6
          ipv6_netmask      = tonumber(network_interface.value.netmaskv6)
        }
      }
 
      dns_server_list	= each.value.dns_servers
      ipv4_gateway	= [ for i in each.value.network_adapters : i.gateway if contains(keys(i), "gateway") ][0]
      ipv6_gateway	= [ for i in each.value.network_adapters : i.gatewayv6 if contains(keys(i), "gatewayv6") ][0]
    }
  }
}

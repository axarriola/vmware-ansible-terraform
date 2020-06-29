# vmware-ansible-terraform
Deploy virtual machines to vsphere with Terraform using an ansible inventory.

## Use case
Initially, the whole deployment and configuration lifecycle was managed by Ansible. Later on, a requirement to move the deployment part to Terraform came in (because it is specialized in IaC).
All the configuration management playbooks and roles depended on ansible inventory/group variables, so the ansible inventory was required as a data source.
In order to avoid having two separate host data sources (ansible inventory and terraform resources) with overlapping values, a couple stages were added to the pipeline in order to use the same ansible inventory to deploy the Virtual Machines with Terraform.

## Dockerfile

The Dockerfile-terraform file can be used to build a container image with Terraform and the terraform vsphere provider. The versions are added as arguments, current ones are:
```
ARG TERRAFORM_VERSION=0.12.26
ARG VSPHERE_PLUGIN_VERSION=1.18.3
```

For the stages that use an ansible container, this repository can be used to create the corresponding image: https://github.com/axarriola/ansible-docker-image

# Workflow

## Summary
The yaml ansible inventory is converted to json and some variables are extracted from it (also written to json). These json files are read by terraform as variables
and used to create the data sources, the terraform vsphere_virtual_machine resources are created by looping the json inventory. The steps are shown in the `.gitlab-ci.yml`
file. After the terraform deployment, ansible can be executed with the original ansible inventory file to configure the VMs (that stage is hashed out in .gitlab-ci.yml).

## Terraform variables preparation

Prior to executing terraform, the necessary terraform variable files need to be created from the ansible inventory file.

* **Inputs:** ansible inventory (ansible_inventory.yml)
* **Outputs:**
  * inventory.tfvars.json is created by converting the ansible inventory from yaml to json using `ansible-inventory ansible_inventory.yml --list`.
  * inventory_vars.tfvars.json is created by executing `python create_vars_json.py ansible_inventory.yml` to extract the datastore names, portgroup names and VM template names that will need to be imported by terraform as data sources.

Examples of both output files were added in this repository as inventory.tfvars.json.example and inventory_vars.tfvars.json.example. Both can be safely deleted, as they are created dynamically (as explained above).

## Terraform deployment

Initialize terraform plugins with `terraform init -plugin-dir="/opt/.terraform/plugins"`, the plugin directory with the vsphere provider plugin is present in the docker image.

Optionally, you can seet the $TAINT_GUEST variable with a host you want to be tainted (destroyed and then deployed again). This variable can be sent inside a trigger/webhook.

Plan the changes with `terraform plan -var="vsphere_user=${VSPHERE_USER}" -var="vsphere_password=${VSPHERE_PASSWORD}" -var-file="inventory_vars.tfvars.json" -var-file="inventory.tfvars.json" -state="ansible_inventory.yml.tfstate" -out=tfplan`.
The vsphere user and password are currently in .gitlab-ci.yml, but it definitely shouldn't. You should add it as private variables in your cicd tool or with an external tool like Vault.

Apply the changes with `terraform apply -state="ansible_inventory.yml.tfstate" tfplan`.

# Further development

## Terraform Backend
In order to use this after the first deployment, you need to setup a backend for terraform to save/retrieve the state before/after each deployment.
This is a personal choice and depends on what you have avaiable, in my case it was artifactory. You can search the possibilities here https://www.terraform.io/docs/backends/types/index.html.

## IPv4 Netmask
If your ipv4 netmask in the ansible inventory is not in CIDR notation ((like in my case)[https://github.com/axarriola/vmware-ansible-terraform/blob/d4401d389c26e661790508d9012229c993b36401/vsphere_vms.tf#L52]), you would need to translate it. I didn't find a filter to do this in terraform, I might do one if I get the time.

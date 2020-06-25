#!/usr/bin/env python

import os
import sys
import json

def create_vars_json(inventories):
    output_file = os.environ.get("VARS_JSON", "inventory_vars.tfvars.json")
    
    variables = dict(networks=list(),templates=list(),datastores=list())

    for inventory_path in inventories:

        with open(inventory_path,"r") as inventory_file:
            inventory = json.loads(inventory_file.read())
    
        hostvars = inventory["_meta"]["hostvars"]
        variables["networks"].extend(net_if["name"]
                                         for var in hostvars.values()
                                         for net_if in var["network_adapters"])
    
        variables["templates"].extend(var["guest_template"]
                                         for var in hostvars.values()
                                         if "guest_template" in var)
    
        variables["datastores"].extend(disk_layout["datastore"]
                                           for var in hostvars.values()
                                           for disk_layout in var["disk_layout"] if "datastore" in disk_layout)
    
    if os.path.isfile(output_file):
        existing_vars = json.loads(open(output_file, "r").read())
        for k in variables:
            if k in existing_vars:
                variables[k].extend(existing_vars[k])

    for k in variables:
        variables[k] = list(set(variables[k]))

    with open(output_file, "w") as nt:
        json.dump(variables, nt, indent=2)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Specify inventory paths as arguments!")
        sys.exit(1)
    print(str(sys.argv[1:]))
    create_vars_json(sys.argv[1:])

# Consul Testing & Validation on OCI

[![License: UPL](https://img.shields.io/badge/license-UPL-green)](https://img.shields.io/badge/license-UPL-green) [![Quality gate](https://sonarcloud.io/api/project_badges/quality_gate?project=oracle-devrel_consul-testing-validation)](https://sonarcloud.io/dashboard?id=oracle-devrel_consul-testing-validation)

## Introduction
This repository contains a bare-bones environment that runs [Consul](https://www.consul.io), intended to test and validate [Consul](https://www.consul.io) on top of [Oracle Cloud Infrastructure (OCI)](https://www.oracle.com/cloud).

There are two topologies in this repo:

* [Consul (single region)](./terraform_single_region)
* [Consul Terraform Sync](./terraform_cts)

Please see the README in each directory for more description on what/how to use it.

## Getting Started
### Sensitive Values to Record
It would be a good idea to keep track of the encryption key (found in `/tmp/keygen`) used for encrypting/securing gossip communications.  You'll also want to store the super-user secret/token (found in `tmp/consul_bootstrap`) which might be needed at a later time.  Log these in your favorite password manager or on a sticky by your monitor (no, this really isn't a good idea - don't do it).  These are available on any of the Consul servers.

### Accessing the Consul Web UI
You'll need to do a bit of port-forwarding trickery to get this working:

```
ssh -L 8500:172.16.0.2:8500 -i <your_SSH_private_key> -A opc@<bastion_public_ip>
```

Once this is running, point your web browser to `http://127.0.0.1:8500`.  If you get to a screen that requires you to login, use the `SecretID` found in `/tmp/consul_bootstrap`.  This is your "super-user" token (for lack of a better definition).

### Visiting the LB
You may visit the LB by going to the public IP in your web browser.  Note that there is no encryption used (this is only a sample, not a production-ready use-case).

### Prerequisites
You must have an OCI account.  [Click here](https://www.oracle.com/cloud/free/?source=:ow:o:s:nav::DevoGetStarted&intcmp=:ow:o:s:nav::DevoGetStarted) to create a new cloud account.

## Notes/Issues
None at this time.

## URLs
### Consul Installation
* https://devopscube.com/setup-consul-cluster-guide/
* https://learn.hashicorp.com/tutorials/consul/deployment-guide

## Contributing
This project is open source.  Please submit your contributions by forking this repository and submitting a pull request!  Oracle appreciates any contributions that are made by the open source community.

## License
Copyright (c) 2021 Oracle and/or its affiliates.

Licensed under the Universal Permissive License (UPL), Version 1.0.

See [LICENSE](LICENSE) for more details.

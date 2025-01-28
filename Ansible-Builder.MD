# Azure Execution Environment for Ansible

This guide provides steps to create an execution environment for running Ansible in Azure using `ansible-builder`. 
The environment uses a minimal Red Hat Enterprise Linux (RHEL) image and includes the `azure.azcollection` for Azure-specific Ansible modules.

## Prerequisites

- Install [Ansible Builder](https://ansible-builder.readthedocs.io/):
   
  # pip3 install ansible-builder
  ```

Steps to Set Up the Execution Environment

1. Create the execution-environment.yml File
Create a file named execution-environment.yml with the following content to define the dependencies:
```yaml
---
version: 3
images:
  base_image:
    name: registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel8:latest
dependencies:
  galaxy:
    collections:
      - azure.azcollection
options:
  package_manager_path: /usr/bin/microdnf
```

2. Log in to the Red Hat Registry
Authenticate with Red Hat's registry to access the base image:
```bash
# podman login registry.redhat.io
```
3. Build the Custom Image
Run the ansible-builder command in the directory containing the execution-environment.yml file:
```bash
# ansible-builder build --tag custom-azure-ee:latest
```
4. Tag the created Image
```bash
# podman tag custom_azure_ee quay.io/amainali/custom_azure_ee:latest
```
5. Log in to Quay.io through the web UI, and complete initial configuration.

6. Log in to Quay.io via CLI:
```bash
# podman login quay.io
```
7. Push the image to your Quay.io repository:
```bash
# podman push quay.io/<username>/custom_azure_ee:latest
```

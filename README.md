Job Templates Linux Environment
Name: Create Linux VM
Playbook: create_linux_vm.yml
Description: Creates a Linux (Rhel7/RHEL8) machine in vSphere
Name: Create Windows AD user - Linux
Playbook: create_ad_user.yml
Description: Creates an AD user in Windows AD server for Linux User
Name: Configure DNS server
Playbook: configure_dns_sever.yml
Description: Configures RHEL8 DNS server with the hostname/IP on forward and reverse zone
Name: Linux Post Patching
Playbook: linux_post_configuration.yml
Description: Upgrades all the packages except for the kernel-related in the newly created RHEL7 machines, and all package including kernel-related for RHEL8 machines.
Name: Linux Success Message
Playbook: success_msg.yml
Description: Displays a success message after the workflow template has been completed


Workflow-Job Templates Linux Environment
Name: Complete Linux VM Creation
Description: This workflow job template includes the following steps:
Asks the ansible admin for approval to run this Workflow
Creates an RHEL7/RHEL8 VM in vSphere-based on survey answers
Adds the hostname and IP address of the freshly created VM into the forward and reverse DNS zone on the DNS server
Creates a user account in a freshly created Linux Machine with admin rights
Creates a user account in Windows AD with admin rights
Patches the freshly created server (No Kernal Patch in RHEL7, Kernel patch present in RHEL8)
Sends the success message with the details
This Playbook and Workflow job templates are designed for Linux environment, which enable you to create Linux VM, configure DNS server, Linux post patching and Linux success message. It also includes step by step process of complete Linux VM creation with the approval of ansible admin.

**AAP-Linux-DEMO**

AAP - Job Templates 
| Name | Playbook | Descrription|
| ----- | --------| ------------|
|Create Linux VM|create_linux_vm.yml|Creates a Linux (Rhel7/RHEL8) machine in vSphere|
|Create Windows AD user - Linux|create_ad_user.yml|Creates an AD user in Windows AD server for Linux User|
|Configure DNS server|configure_dns_sever.yml|Configures RHEL8 DNS server with the hostname/IP on forward and reverse zone|
|Linux Post Patching|linux_post_configuration.yml|Upgrades all the packages except for the kernel-related in the newly created RHEL7 machines, and all package including kernel-related for RHEL8 machines.|
|Linux Success Message|success_msg.yml|Displays a success message after the workflow template has been completed|

AAP - Workflow-Job Template
| Name | Templates | Description|
| ----- | --------| ------------|
|Complete Linux VM Creation|Workflow Approval: Asking Ansible-Admin for approval<br />Create Linux VM<br />Configure DNS server<br />Linux Post Patching<br />Linux Success Message|Steps done on this workflow job template:<br />1. Asks the ansible admin for approval to run this Workflow<br />2. Creates an RHEL7/RHEL8 VM in vSphere-based on survey answers<br />3. Adds the hostname and IP address of the freshly created VM into the forward and reverse DNS zone on the DNS server<br />4. Creates a user account in a freshly created Linux Machine with admin rights<br />5. Creates a user account in Windows AD with admin rights<br />6. Patches the freshly created server (No Kernal Patch in RHEL7, Kernel patch present in RHEL8)<br />Sends the success message with the details|

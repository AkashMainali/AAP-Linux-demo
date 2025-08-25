# Architecting a Production-Grade Ansible Automation Platform 2.5 Deployment

This guide provides a comprehensive walkthrough for deploying Red Hat Ansible Automation Platform (AAP) 2.5 in a **production-ready, single-node, containerized configuration**. [cite_start]It is based on the "Container Growth Topology", a supported reference architecture from Red Hat[cite: 23].

[cite_start]This guide emphasizes that a successful production deployment goes beyond the initial installation, requiring a strategic plan for security, resilience, monitoring, and lifecycle management[cite: 5].

---

## 📋 Table of Contents

1.  [Architecture Overview](#-architecture-overview)
2.  [Host Environment Preparation](#-host-environment-preparation)
3.  [Step-by-Step Installation](#-step-by-step-installation)
4.  [Security Hardening](#-security-hardening)
5.  [Monitoring, Backup, and Recovery](#-monitoring-backup-and-recovery)
6.  [Advanced Enterprise Configuration](#-advanced-enterprise-configuration)

---

## 🏗️ Architecture Overview

[cite_start]AAP 2.5 shifts from a monolithic, RPM-based installation to a suite of containerized microservices running on Podman[cite: 7, 9]. [cite_start]This modern architecture improves component isolation and security but introduces new operational complexities[cite: 8].

### Key Components

* [cite_start]**Automation Controller**: The core engine for orchestrating Ansible Playbooks, managing inventory, and providing Role-Based Access Control (RBAC)[cite: 12].
* [cite_start]**Private Automation Hub (PAH)**: A local repository for managing and distributing certified and custom automation content, including collections and execution environments[cite: 13, 14].
* [cite_start]**Event-Driven Ansible (EDA) Controller**: Processes real-time events from various sources to trigger automated responses[cite: 15].
* [cite_start]**Platform Gateway**: A unified entry point and reverse proxy for all UI and API interactions, routing requests to the appropriate backend service[cite: 16, 17].

### "Container Growth Topology"

[cite_start]This guide focuses on the **single-node topology**, which installs all core components—Controller, Hub, EDA, Database, and Redis—as containers on a single RHEL host[cite: 23, 25].

> [cite_start]**⚠️ Important Consideration**: This topology represents a **single point of failure**[cite: 27]. [cite_start]A hardware or OS-level issue on the node will result in a complete platform outage[cite: 29]. [cite_start]Scaling to a multi-node setup requires a full migration, not an in-place upgrade[cite: 30, 31].

---

## 🖥️ Host Environment Preparation

[cite_start]Meticulous host preparation is the most effective way to prevent common installation failures and ensure long-term operational health[cite: 41, 42].

### Hardware Recommendations

[cite_start]While Red Hat defines minimums, these recommendations are strongly advised for production environments[cite: 45].

| Component | Minimum Requirement | **Production Recommendation** | Verification Command |
| :--- | :--- | :--- | :--- |
| **CPU Cores** | [cite_start]4 [cite: 47] | [cite_start]**8+** [cite: 48] | [cite_start]`lscpu \| grep '^CPU(s):'` [cite: 74] |
| **RAM** | [cite_start]16 GB [cite: 47] | [cite_start]**32 GB+** [cite: 48] | [cite_start]`free -g` [cite: 74] |
| **Disk Space** | [cite_start]60 GB [cite: 47] | [cite_start]**100 GB+** [cite: 74] | [cite_start]`df -h /` [cite: 74] |
| **/var/tmp Space** | [cite_start]3 GB (Offline) [cite: 54] | [cite_start]**12 GB+** [cite: 56] | [cite_start]`df -h /var/tmp` [cite: 74] |
| **Disk IOPS** | [cite_start]3000 [cite: 47] | [cite_start]**3000+** [cite: 74] | [cite_start]`fio` [cite: 74] |

### System & Network Prerequisites

* [cite_start]**OS**: Red Hat Enterprise Linux 9.2 or a later minor version of RHEL 9[cite: 59, 74].
* [cite_start]**Subscriptions**: Both RHEL (for BaseOS and AppStream) and AAP subscriptions must be attached and current[cite: 36, 61, 74].
* [cite_start]**Software**: The `ansible-core` package (version 2.14) must be installed from RHEL repositories before running the installer[cite: 63, 64].
* [cite_start]**Hostname**: The host must have a static, DNS-resolvable Fully Qualified Domain Name (FQDN)[cite: 67, 74].
* [cite_start]**Dedicated User**: The installation must be run by a dedicated non-root user (e.g., `aap`) with passwordless `sudo` privileges[cite: 79, 83, 74].
* [cite_start]**SELinux**: Must be enabled and in `Enforcing` mode[cite: 85].
* [cite_start]**Firewall Ports**: The following ports must be open for inbound traffic[cite: 70]:
    * [cite_start]`80/TCP` (HTTP Redirect) [cite: 76]
    * [cite_start]`443/TCP` (HTTPS UI/API) [cite: 76]
    * [cite_start]`27199/TCP` (Receptor Control Plane) [cite: 76]

---

## 🚀 Step-by-Step Installation

### 1. Obtain the Installer

[cite_start]Download the "Ansible Automation Platform 2.5 Containerized Setup Bundle" from the Red Hat Customer Portal and unpack it on the host[cite: 94, 96].

```bash
tar xfvz ansible-automation-platform-containerized-setup-bundle-*.tar.gz
```

### 2. Configure the Inventory

[cite_start]The inventory file is the central configuration for the deployment[cite: 104].

1.  [cite_start]Copy the template: `cp inventory-growth inventory-prod`[cite: 106].
2.  [cite_start]**Host Definitions**: Ensure the host's FQDN is listed under all component groups (`[automationgateway]`, `[automationcontroller]`, etc.)[cite: 108, 109].
3.  [cite_start]**Variable Configuration (`[all:vars]`)**: Set all required variables[cite: 110]. [cite_start]**Passwords should be secured with Ansible Vault**[cite: 123].

    ```ini
    # Example inventory-prod snippet
    [all:vars]
    ansible_connection=local

    # Use a Registry Service Account from cloud.redhat.com
    registry_username = '1234567|aap_installer'
    registry_password = '<your_service_account_token>'

    # Admin passwords (use ansible-vault to encrypt these)
    postgresql_admin_password = '<strong_password_1>'
    gateway_admin_password = '<strong_password_2>'
    controller_admin_password = '<strong_password_3>'
    hub_admin_password = '<strong_password_4>'

    # Paths for custom TLS certs (configure in hardening step)
    # gateway_ssl_cert = '/path/to/aap.crt'
    # gateway_ssl_key = '/path/to/aap.key'
    # custom_ca_cert = '/path/to/ca.pem'
    ```

### 3. Execute the Playbook

[cite_start]Run the installer from within the unpacked directory[cite: 117].

```bash
# For production, use Ansible Vault for passwords
ansible-playbook -i inventory-prod --ask-vault-pass -e @vars/secrets.yml ansible.containerized_installer.install
```

### 4. Post-Installation Verification

1.  [cite_start]**Check Container Status**: Ensure all service containers are running[cite: 131].
    ```bash
    podman ps --format "{{.Names}}"
    ```
2.  [cite_start]**Inspect Logs**: If a container is failing, check its logs using `journald`[cite: 135].
    ```bash
    journalctl CONTAINER_NAME=automation-controller-web
    ```
3.  [cite_start]**UI and Subscription Check**: Log in to `https://<your_fqdn>` and verify that the UI is accessible and the AAP subscription is recognized as compliant[cite: 140, 143].

---

## 🔒 Security Hardening

### Custom SSL/TLS Certificates

[cite_start]The default self-signed certificates are not suitable for production and should be replaced with certificates from a trusted Certificate Authority (CA)[cite: 147, 148].

1.  [cite_start]Obtain a certificate, private key, and CA bundle for your FQDN[cite: 150].
2.  [cite_start]Place the files on the AAP host[cite: 151].
3.  [cite_start]Uncomment and set the `gateway_ssl_cert`, `gateway_ssl_key`, and `custom_ca_cert` variables in your inventory file[cite: 152].
4.  [cite_start]Re-run the installer playbook[cite: 153, 154].

> [cite_start]**🚨 Receptor TLS Warning**: The `receptor` service can fail its TLS handshake with wildcard certificates[cite: 156]. [cite_start]It is **highly recommended** to issue a certificate with the specific FQDN of the AAP host listed as a Subject Alternative Name (SAN)[cite: 156]. [cite_start]Failure can cause jobs to be stuck in a "pending" state indefinitely[cite: 157].

### Credential Management

* [cite_start]**External Vaults**: For mature environments, integrate with an external secrets manager like HashiCorp Vault or CyberArk Conjur[cite: 168]. [cite_start]This allows AAP to fetch credentials dynamically at runtime, centralizing secret management[cite: 170].
* [cite_start]**RBAC Model**: Use Organizations and Teams to delegate access and enforce separation of duties[cite: 172, 175]. [cite_start]Strictly limit the number of System Administrators[cite: 173].
* [cite_start]**Centralized Logging**: Forward logs to a central platform (Splunk, Elastic) for auditing and compliance[cite: 181, 182, 183]. [cite_start]Configure this in the Controller UI under `Settings > Logging Settings`[cite: 184].

---

## 🛠️ Monitoring, Backup, and Recovery

### Monitoring Strategy

[cite_start]Monitor the platform at three distinct layers to ensure visibility[cite: 191].

1.  [cite_start]**Host System**: Monitor CPU, memory, disk space, and I/O using tools like Prometheus Node Exporter[cite: 192, 193, 195].
2.  [cite_start]**Container Runtime**: Monitor container status (running, restarting) and resource usage with a tool like `prometheus-podman-exporter`[cite: 196, 198].
3.  [cite_start]**Application Performance**: Scrape the Prometheus-compatible endpoint at `/api/controller/v2/metrics/` to track running jobs (`awx_jobs_running`), active sessions (`awx_sessions_total`), and queue depth[cite: 201, 202].

### Backup and Restore

* [cite_start]**Supported Method**: Use **only** the playbooks provided by the installer collection (`ansible.containerized_installer.backup` and `ansible.containerized_installer.restore`)[cite: 210]. [cite_start]Manual methods like `pg_dump` are unsupported and will likely result in a non-functional restoration[cite: 211].
* **Backup Command**:
    ```bash
    ansible-playbook -i inventory-prod ansible.containerized_installer.backup
    ```
* [cite_start]**Critical Practice**: Backups should be run regularly and the resulting archives **copied to a secure, off-host location**[cite: 231].

---

## ⚙️ Advanced Enterprise Configuration

### Content Management

* [cite_start]**Private Automation Hub (PAH)**: Use PAH as a local, curated repository for all automation content[cite: 237]. [cite_start]Synchronize certified collections from Red Hat and upload custom-developed content[cite: 239, 240]. [cite_start]Configure the Controller to use PAH as its exclusive source for collections to ensure only vetted content is used[cite: 242, 243].

### Execution Environments (EEs)

* [cite_start]**Consistent Runtimes**: EEs are container images that bundle all dependencies (`ansible-core`, collections, Python libraries) required for automation to run, solving the "dependency hell" problem[cite: 245, 246, 247].
* [cite_start]**Build Custom EEs**: Use the `ansible-builder` utility to create custom EEs, publish them to PAH's container registry, and assign them to Job Templates in the Controller[cite: 248, 252, 253].

### GitOps Integration

* [cite_start]**Source Control**: All Ansible Playbooks and roles should be stored and managed in a source control system like Git[cite: 256].
* [cite_start]**Controller Projects**: Configure Projects in the Controller to point to Git repositories[cite: 257]. [cite_start]This ensures you are always running the latest, version-controlled automation code and enables peer review and rollback capabilities[cite: 258, 259].
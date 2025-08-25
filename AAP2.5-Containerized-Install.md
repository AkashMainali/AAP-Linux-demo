# Architecting a Production-Grade Ansible Automation Platform 2.5 Deployment

This guide provides a comprehensive walkthrough for deploying Red Hat Ansible Automation Platform (AAP) 2.5 in a **production-ready, single-node, containerized configuration**. It is based on the "Container Growth Topology", a supported reference architecture from Red Hat[cite: 23].

This guide emphasizes that a successful production deployment goes beyond the initial installation, requiring a strategic plan for security, resilience, monitoring, and lifecycle management[cite: 5].

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

AAP 2.5 shifts from a monolithic, RPM-based installation to a suite of containerized microservices running on Podman[cite: 7, 9]. This modern architecture improves component isolation and security but introduces new operational complexities[cite: 8].

### Key Components

* **Automation Controller**: The core engine for orchestrating Ansible Playbooks, managing inventory, and providing Role-Based Access Control (RBAC)[cite: 12].
* **Private Automation Hub (PAH)**: A local repository for managing and distributing certified and custom automation content, including collections and execution environments[cite: 13, 14].
* **Event-Driven Ansible (EDA) Controller**: Processes real-time events from various sources to trigger automated responses[cite: 15].
* **Platform Gateway**: A unified entry point and reverse proxy for all UI and API interactions, routing requests to the appropriate backend service[cite: 16, 17].

### "Container Growth Topology"

This guide focuses on the **single-node topology**, which installs all core components—Controller, Hub, EDA, Database, and Redis—as containers on a single RHEL host[cite: 23, 25].

> **⚠️ Important Consideration**: This topology represents a **single point of failure**[cite: 27]. A hardware or OS-level issue on the node will result in a complete platform outage[cite: 29]. Scaling to a multi-node setup requires a full migration, not an in-place upgrade[cite: 30, 31].

---

## 🖥️ Host Environment Preparation

Meticulous host preparation is the most effective way to prevent common installation failures and ensure long-term operational health[cite: 41, 42].

### Hardware Recommendations

While Red Hat defines minimums, these recommendations are strongly advised for production environments[cite: 45].

| Component | Minimum Requirement | **Production Recommendation** | Verification Command |
| :--- | :--- | :--- | :--- |
| **CPU Cores** | 4 [cite: 47] | **8+** [cite: 48] | `lscpu \| grep '^CPU(s):'` [cite: 74] |
| **RAM** | 16 GB [cite: 47] | **32 GB+** [cite: 48] | `free -g` [cite: 74] |
| **Disk Space** | 60 GB [cite: 47] | **100 GB+** [cite: 74] | `df -h /` [cite: 74] |
| **/var/tmp Space** | 3 GB (Offline) [cite: 54] | **12 GB+** [cite: 56] | `df -h /var/tmp` [cite: 74] |
| **Disk IOPS** | 3000 [cite: 47] | **3000+** [cite: 74] | `fio` [cite: 74] |

### System & Network Prerequisites

* **OS**: Red Hat Enterprise Linux 9.2 or a later minor version of RHEL 9[cite: 59, 74].
* **Subscriptions**: Both RHEL (for BaseOS and AppStream) and AAP subscriptions must be attached and current[cite: 36, 61, 74].
* **Software**: The `ansible-core` package (version 2.14) must be installed from RHEL repositories before running the installer[cite: 63, 64].
* **Hostname**: The host must have a static, DNS-resolvable Fully Qualified Domain Name (FQDN)[cite: 67, 74].
* **Dedicated User**: The installation must be run by a dedicated non-root user (e.g., `aap`) with passwordless `sudo` privileges[cite: 79, 83, 74].
* **SELinux**: Must be enabled and in `Enforcing` mode[cite: 85].
* **Firewall Ports**: The following ports must be open for inbound traffic[cite: 70]:
    * `80/TCP` (HTTP Redirect) [cite: 76]
    * `443/TCP` (HTTPS UI/API) [cite: 76]
    * `27199/TCP` (Receptor Control Plane) [cite: 76]

---

## 🚀 Step-by-Step Installation

### 1. Obtain the Installer

Download the "Ansible Automation Platform 2.5 Containerized Setup Bundle" from the Red Hat Customer Portal and unpack it on the host[cite: 94, 96].

```bash
tar xfvz ansible-automation-platform-containerized-setup-bundle-*.tar.gz
```

### 2. Configure the Inventory

The inventory file is the central configuration for the deployment[cite: 104].

1.  Copy the template: `cp inventory-growth inventory-prod`[cite: 106].
2.  **Host Definitions**: Ensure the host's FQDN is listed under all component groups (`[automationgateway]`, `[automationcontroller]`, etc.)[cite: 108, 109].
3.  **Variable Configuration (`[all:vars]`)**: Set all required variables[cite: 110]. **Passwords should be secured with Ansible Vault**[cite: 123].

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

Run the installer from within the unpacked directory[cite: 117].

```bash
# For production, use Ansible Vault for passwords
ansible-playbook -i inventory-prod --ask-vault-pass -e @vars/secrets.yml ansible.containerized_installer.install
```

### 4. Post-Installation Verification

1.  **Check Container Status**: Ensure all service containers are running[cite: 131].
    ```bash
    podman ps --format "{{.Names}}"
    ```
2.  **Inspect Logs**: If a container is failing, check its logs using `journald`[cite: 135].
    ```bash
    journalctl CONTAINER_NAME=automation-controller-web
    ```
3.  **UI and Subscription Check**: Log in to `https://<your_fqdn>` and verify that the UI is accessible and the AAP subscription is recognized as compliant[cite: 140, 143].

---

## 🔒 Security Hardening

### Custom SSL/TLS Certificates

The default self-signed certificates are not suitable for production and should be replaced with certificates from a trusted Certificate Authority (CA)[cite: 147, 148].

1.  Obtain a certificate, private key, and CA bundle for your FQDN[cite: 150].
2.  Place the files on the AAP host[cite: 151].
3.  Uncomment and set the `gateway_ssl_cert`, `gateway_ssl_key`, and `custom_ca_cert` variables in your inventory file[cite: 152].
4.  Re-run the installer playbook[cite: 153, 154].

> **🚨 Receptor TLS Warning**: The `receptor` service can fail its TLS handshake with wildcard certificates[cite: 156]. It is **highly recommended** to issue a certificate with the specific FQDN of the AAP host listed as a Subject Alternative Name (SAN)[cite: 156]. Failure can cause jobs to be stuck in a "pending" state indefinitely[cite: 157].

### Credential Management

* **External Vaults**: For mature environments, integrate with an external secrets manager like HashiCorp Vault or CyberArk Conjur[cite: 168]. This allows AAP to fetch credentials dynamically at runtime, centralizing secret management[cite: 170].
* **RBAC Model**: Use Organizations and Teams to delegate access and enforce separation of duties[cite: 172, 175]. Strictly limit the number of System Administrators[cite: 173].
* **Centralized Logging**: Forward logs to a central platform (Splunk, Elastic) for auditing and compliance[cite: 181, 182, 183]. Configure this in the Controller UI under `Settings > Logging Settings`[cite: 184].

---

## 🛠️ Monitoring, Backup, and Recovery

### Monitoring Strategy

Monitor the platform at three distinct layers to ensure visibility[cite: 191].

1.  **Host System**: Monitor CPU, memory, disk space, and I/O using tools like Prometheus Node Exporter[cite: 192, 193, 195].
2.  **Container Runtime**: Monitor container status (running, restarting) and resource usage with a tool like `prometheus-podman-exporter`[cite: 196, 198].
3.  **Application Performance**: Scrape the Prometheus-compatible endpoint at `/api/controller/v2/metrics/` to track running jobs (`awx_jobs_running`), active sessions (`awx_sessions_total`), and queue depth[cite: 201, 202].

### Backup and Restore

* **Supported Method**: Use **only** the playbooks provided by the installer collection (`ansible.containerized_installer.backup` and `ansible.containerized_installer.restore`)[cite: 210]. Manual methods like `pg_dump` are unsupported and will likely result in a non-functional restoration[cite: 211].
* **Backup Command**:
    ```bash
    ansible-playbook -i inventory-prod ansible.containerized_installer.backup
    ```
* **Critical Practice**: Backups should be run regularly and the resulting archives **copied to a secure, off-host location**[cite: 231].

---

## ⚙️ Advanced Enterprise Configuration

### Content Management

* **Private Automation Hub (PAH)**: Use PAH as a local, curated repository for all automation content[cite: 237]. Synchronize certified collections from Red Hat and upload custom-developed content[cite: 239, 240]. Configure the Controller to use PAH as its exclusive source for collections to ensure only vetted content is used[cite: 242, 243].

### Execution Environments (EEs)

* **Consistent Runtimes**: EEs are container images that bundle all dependencies (`ansible-core`, collections, Python libraries) required for automation to run, solving the "dependency hell" problem[cite: 245, 246, 247].
* **Build Custom EEs**: Use the `ansible-builder` utility to create custom EEs, publish them to PAH's container registry, and assign them to Job Templates in the Controller[cite: 248, 252, 253].

### GitOps Integration

* **Source Control**: All Ansible Playbooks and roles should be stored and managed in a source control system like Git[cite: 256].
* **Controller Projects**: Configure Projects in the Controller to point to Git repositories[cite: 257]. This ensures you are always running the latest, version-controlled automation code and enables peer review and rollback capabilities[cite: 258, 259].
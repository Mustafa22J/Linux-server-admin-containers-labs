\# Linux Network Services SBA (CST8246)



This project is a full implementation of multiple Linux network services using automation scripts and secure configurations.



\---



\## Services Implemented



\### 1. SSH (Secure Remote Access)

\- Key-based authentication

\- Password authentication disabled

\- Secure remote management



\---



\### 2. Samba (File Sharing)

\- Public share with full access

\- Configured for cross-platform access (Linux/Windows)

\- Verified using CIFS mount



\---



\### 3. Apache Web Server

\- Multiple virtual hosts:

&#x20; - www1.yellow.lab

&#x20; - www2.yellow.lab

\- HTTPS secure site:

&#x20; - secure.yellow.lab

\- SSL/TLS configuration using OpenSSL



\---



\### 4. NFS (Network File System)

\- Read/Write access for client network

\- Read-only access for restricted network

\- Verified mount and permission behavior



\---



\## Security Configuration



\- Firewall configured using iptables:

&#x20; - Default DROP policy

&#x20; - Only required ports allowed

\- Services restricted to client network



\---



\## Automation



All services were deployed using Bash scripts:

\- Initial setup script

\- Firewall configuration

\- Service-specific scripts



This ensures repeatable and consistent deployment.



\---



\## Verification



\- curl used to test web services

\- mount used to validate file sharing

\- systemctl used to verify service status

\- iptables used to verify firewall rules



\---



\## Skills Demonstrated



\- Linux system administration

\- Network service deployment

\- Security hardening

\- Automation scripting

\- Troubleshooting and validation


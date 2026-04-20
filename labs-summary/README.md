\# Linux Network Services Labs Summary (CST8246)



This section summarizes the practical labs completed during the course.  

All labs were demonstrated in a controlled lab environment using RHEL-based virtual machines.



\---



\## Apache Web Server



Configured Apache (httpd) with:

\- Multiple virtual hosts

\- Custom document roots

\- SSL/TLS secured site using self-signed certificates

\- Service validation using curl and browser access



Key commands used:

\- httpd -t

\- systemctl restart httpd

\- curl http://hostname



\---



\## Postfix Mail Server



Configured Postfix for sending and receiving mail:

\- Local and remote mail delivery

\- Mail testing using mailx

\- SMTP troubleshooting using telnet / netcat



Key commands:

\- postconf

\- systemctl restart postfix

\- tail -f /var/log/maillog



\---



\## LDAP Directory Services



Configured LDAP server and client:

\- Created directory structure (DIT)

\- Added users and groups using LDIF

\- Queried directory using ldapsearch



Key commands:

\- ldapadd

\- ldapsearch

\- slaptest



\---



\## Samba \& NFS File Sharing



Configured file sharing services:

\- Samba public and restricted shares

\- NFS read/write and read-only access

\- Client mounting and verification



Key commands:

\- smbclient

\- mount -t cifs

\- exportfs -v



\---



\## Skills Demonstrated



\- Linux server administration

\- Network service configuration

\- Automation using Bash scripting

\- Troubleshooting using logs and system tools


\# Linux Server Admin – Containers \& Automation Labs



This repository contains my lab work and practical assessments from \*\*CST8305 – GNU/Linux Server Administration\*\* (Fall 2025).  

The focus of this course is running \*\*Linux in containers (Podman)\*\* on Windows 11, automating administration tasks, and securing services.



> Note: All hands-on work was also demonstrated \*\*in person\*\* during scheduled lab times, following the official course rubrics and instructions.



---



\## Tech Stack



\- \*\*Arch Linux\*\* containers running under \*\*Podman Desktop on Windows 11\*\*

\- \*\*systemd\*\* for services, timers and process control

\- \*\*pacman\*\* package management

\- \*\*OpenVAS / Greenbone\*\* and \*\*nmap\*\* for vulnerability scanning

\- \*\*Podman Compose\*\* and YAML for multi-container apps

\- \*\*Paperless-ngx\*\* self-hosted document management

\- SELinux, networking, DNS and containerized applications



---



\## Repository Layout



```text

practical-03-security-assessment/  # Dionaea honeypot + OpenVAS / nmap security practical

practical-04-paperless-ngx/        # Paperless-ngx multi-container project + backup automation

lab-notes/                         # Short notes summarizing each Linux lab

I do not publish my professor’s lab PDFs or Brightspace content.
Only my own work, summaries, configs and scripts are included here.


Highlighted Practicals
Practical 03 – Security Assessment (Dionaea honeypot)

In this practical I deployed a Dionaea honeypot inside the lab network, discovered its IP, and validated connectivity from Windows.
I then ran a detailed nmap vulnerability script scan and a full OpenVAS (Greenbone) scan against the container:

Verified host discovery and ARP response

Used nmap -d --script "vuln and not http-enum" to scan for open ports and CVEs 

jawi0004_Practical Assessment 3

Ran an OpenVAS Full and Fast scan against the Dionaea IP

Interpreted the report (open services like SMTP, outdated TLS versions, medium-severity findings, mapped CVEs, etc.) 

jawi0004_Practical Assessment 3

Folder: practical-03-security-assessment/
Contains my written security assessment and notes based on the scan results.

Practical 04 – Paperless-ngx (Containerized DMS + Backup Scripts)

This practical is a full small project: deploying paperless-ngx using Podman Compose on Windows and writing backup/restore automation in PowerShell.

Key pieces:

Created consume/, export/ and paperless/ directories and wrote a podman-compose.yml file defining Redis, Postgres, Paperless, Gotenberg and Tika services. 

Practical Assessment #4_ Paperl…

Configured environment files (compose.env, .env) and launched the stack with podman compose up -d.

Exposed the web UI on http://127.0.0.1:8000, created a user with my college ID, and uploaded ≥10 test documents. 

Practical Assessment #4_ Paperl…

Used tools like dirsearch to discover hidden endpoints (/admin/, /accounts/, /api/, /static/, etc.) and documented the results. 

Paperless-ngx

Wrote backup.ps1 and restore.ps1 scripts that:

Stop the Paperless containers with podman compose down

Copy the full paperless directory into a time-stamped backup

Bring the containers back up with podman compose up -d 

Paperless-ngx

Folder: practical-04-paperless-ngx/
Contains my practical write-up and the PowerShell backup/restore scripts.

Lab Summaries

The lab-notes/ folder contains short notes for each lab (no instructor PDFs):

Lab 01 – Installing Podman Desktop
Installed Podman Desktop on Windows 11, created a Podman machine (WSL2 backend), pulled the docker.io/archlinux image and started an Arch container. Created proof files inside /root and exported/imported snapshots. 

Lab Assignment #1 Installing Po…

Lab 02 – Users, Groups & Collaboration
Started Arch with a custom umask, configured password aging in /etc/login.defs, created a linuxops admin group with sudo via /etc/sudoers.d, created users u1, u2, u3, and built a collaborative team share at /srv/teamshare using setgid directories and group permissions. 

Lab Assignment #2 Users and Gro…

Lab 03 – systemd & Logging
Ran Arch with full systemd, enabled persistent journald logs, wrote a healthcheck.sh script + healthcheck.service and timer, configured log rotation for /var/log/healthcheck.log, and created a hog.service to practice CPU throttling and process control. 

Lab Assignment #3 systemd and l…

Lab 04 – Networking & Package Management
Started an Arch container with --network host, configured a static systemd-networkd file for eth0, verified connectivity and DNS (ping, dig, wget), tuned mirrors and installed tools like htop and traceroute, then removed unneeded packages. 

Lab Assignment #4 Networking an…

Lab 06 – SELinux
Notes on enabling SELinux, viewing labels and contexts, and interpreting AVC denials using course-provided lab material. 

Lab Assignment #6_ SELinux - 25…

Lab 07 – Containerized LLM
High-level notes on running a containerized LLM using Podman Desktop and container images (pulling, starting, resource considerations). 

Lab Assignment #7_ Containerize…

Lab 08 – FreeCIV Container
Using Podman Desktop to search for a freeciv-web container image, launch it, and play at least ten turns through a browser on 127.0.0.1, recorded in a demo video. 

Lab Assignment #8_ FreeCIV - 25…

Each note is written in my own words and focuses on what I configured and why, not on copying course handouts.

Academic Integrity & Copyright

## Linux Network Services (CST8246)

This section contains my work from Linux Network Service Administration.

### Highlights:
- Apache Web Server (Virtual Hosts + SSL)
- Postfix Mail Server
- LDAP Directory Services
- Samba & NFS File Sharing
- Full SBA Automation Project

### Structure:
- sba-linux-services/ → Full project implementation
- labs-summary/ → Lab summaries and concepts
- scripts/ → Automation scripts

> Note: Instructor lab PDFs are not included. Only my own work, scripts, and summaries are published.

All official lab instructions, PDFs, and Brightspace content stay on Brightspace – they are not included in this repository.

Only my own work (configs, scripts, notes, screenshots, reports) is uploaded here.

This repository is for my personal portfolio and to show potential employers my Linux and containerization skills.


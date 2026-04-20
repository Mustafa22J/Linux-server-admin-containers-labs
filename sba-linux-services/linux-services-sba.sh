
## Step 0 — Before changing anything

Do this first on **both VMs**:

```bash
hostnamectl
ip addr
ip route
ping -c 3 172.16.30.33
ping -c 3 172.16.31.33
```

Then take a **snapshot now**.

---

## Step 1 — Create one folder for all scripts

This makes it easy to copy everything later to your host machine.

### On SRV

```bash
mkdir -p /root/sba33
cd /root/sba33
```

### On CLT

```bash
mkdir -p /root/sba33
cd /root/sba33
```

---

## Step 2 — Initial setup on SRV

Run on **SRV**:

```bash
id lab >/dev/null 2>&1 || useradd -m lab
echo 'sba' | passwd --stdin lab

hostnamectl set-hostname jawo0004-SRV.yellow33.lab

grep -q 'jawo0004-SRV.yellow33.lab' /etc/hosts || cat >> /etc/hosts <<'EOF'
127.0.0.1   localhost localhost.localdomain
172.16.30.33 jawo0004-SRV.yellow33.lab jawo0004-SRV
172.16.32.33 secure.blue33.lab
EOF

ip addr show ens192 | grep -q '172.16.32.33/24' || ip addr add 172.16.32.33/24 dev ens192
```

Verify:

```bash
hostnamectl
ip addr show ens192
```

---

## Step 3 — Initial setup on CLT

Run on **CLT**:

```bash
id cst8246 >/dev/null 2>&1 || useradd -m cst8246
echo 'sba' | passwd --stdin cst8246

hostnamectl set-hostname jawo0004-CLT.yellow33.lab

grep -q 'jawo0004-CLT.blue33.lab' /etc/hosts || cat >> /etc/hosts <<'EOF'
127.0.0.1   localhost localhost.localdomain
172.16.31.33 jawo0004-CLT.yellow33.lab jawo0004-CLT
172.16.30.33 jawo0004-SRV.yellow33.lab jawo0004-SRV www1.yellow.lab www2.yellow.lab
172.16.32.33 secure.yellow.lab
EOF
```

Verify:

```bash
hostnamectl
getent hosts www1.yellow.lab
getent hosts secure.yellow.lab
```

---

## Step 4 — Prepare SSH safely

Do **not** disable passwords yet.

### On SRV

```bash
mkdir -p /home/lab/.ssh
chown final:final /home/lab/.ssh
chmod 700 /home/lab/.ssh
grep -q '^PubkeyAuthentication yes' /etc/ssh/sshd_config || echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config
grep -q '^PermitRootLogin' /etc/ssh/sshd_config && \
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config || \
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

systemctl enable sshd
systemctl restart sshd
```

### On CLT, as user `cst8246`

```bash
su - cst8246
mkdir -p ~/.ssh
chmod 700 ~/.ssh
[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
ssh-copy-id lab@172.16.30.33
ssh-copy-id root@172.16.30.33
exit
```

Validate from **CLT**:

```bash
su - cst8246
ssh lab@172.16.30.33 'hostname'
ssh root@172.16.30.33 'hostname'
exit
```

Only **after both work**, on **SRV** you may turn off password auth:

```bash
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
```

Test again from CLT:

```bash
su - cst8246
ssh lab@172.16.30.33 'hostname'
ssh root@172.16.30.33 'hostname'
exit
```

---

## Step 5 — Firewall with iptables

This must be done **after SSH key login is confirmed**.

### On SRV

```bash
dnf install -y iptables iptables-services

iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# allow loopback
iptables -A INPUT -i lo -j ACCEPT

# allow established/related traffic
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# =========================================================
# SELECTED SERVICES ONLY
# =========================================================

# SSH (selected minor) -> allow only from client network
iptables -A INPUT -s 172.16.31.0/24 -p tcp --dport 22 -j ACCEPT

# Samba Public Share (selected minor) -> allow only from client network
iptables -A INPUT -s 172.16.31.0/24 -p tcp -m multiport --dports 139,445 -j ACCEPT
iptables -A INPUT -s 172.16.31.0/24 -p udp -m multiport --dports 137,138 -j ACCEPT

# Advanced Web Hosting (selected major) -> allow only from client network
iptables -A INPUT -s 172.16.31.0/24 -p tcp -m multiport --dports 80,443 -j ACCEPT

# Advanced NFS (selected major)
# RW from 172.16.31.0/24
# RO test from 172.16.30.0/24
for net in 172.16.31.0/24 172.16.30.0/24; do
  iptables -A INPUT -s $net -p tcp --dport 111 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 111 -j ACCEPT
  iptables -A INPUT -s $net -p tcp --dport 2049 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 2049 -j ACCEPT
  iptables -A INPUT -s $net -p tcp --dport 20048 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 20048 -j ACCEPT
  iptables -A INPUT -s $net -p tcp --dport 32765 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 32765 -j ACCEPT
  iptables -A INPUT -s $net -p tcp --dport 32766 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 32766 -j ACCEPT
done

# =========================================================
# NOT SELECTED SERVICES
# =========================================================
# DNS   -> blocked by default DROP (53 tcp/udp not allowed)
# Mail  -> blocked by default DROP (25 tcp not allowed)
# LDAP  -> blocked by default DROP (389 tcp not allowed)
# Any other ports/services -> blocked by default DROP

service iptables save
systemctl enable iptables
systemctl restart iptables

iptables -L -n --line-numbers
```

That follows the exam rule: client network allowed, `172.16.30.0/24` and `172.16.32.0/24` blocked except for the required NFS exception. 

---

## Step 6 — Samba Public Share

### On SRV

```bash
dnf install -y samba samba-client

mkdir -p /srv/samba/public
chmod 0777 /srv/samba/public
chown nobody:nobody /srv/samba/public

cat > /etc/samba/smb.conf <<'EOF'
[global]
   workgroup = WORKGROUP
   server string = SBA Samba Server
   security = user
   map to guest = Bad User
   guest account = nobody

[samba-public]
   path = /srv/samba/public
   browseable = yes
   writable = yes
   guest ok = yes
   public = yes
   read only = no
   force user = nobody
EOF

systemctl enable smb nmb
systemctl restart smb nmb

setsebool -P samba_export_all_rw on
chcon -R -t samba_share_t /srv/samba/public
```

Check:

```bash
testparm
systemctl status smb --no-pager
```

### On CLT

```bash
dnf install -y cifs-utils
mkdir -p /mnt/samba-public
mount -t cifs //172.16.30.33/samba-public /mnt/samba-public -o guest,vers=3.0
echo 'Mustafa Jawish - 33' > /mnt/samba-public/readme.smb
ls -l /mnt/samba-public
cat /mnt/samba-public/readme.smb
```

### Back on SRV

```bash
ls -l /srv/samba/public
cat /srv/samba/public/readme.smb
```

---

## Step 7 — Advanced Web Hosting

You selected this major service, so configure all 3 sites.

### On SRV
dnf install -y httpd mod_ssl

mkdir -p /var/www/www1
mkdir -p /var/www/www2
mkdir -p /var/www/secure

echo '33 - www1.yellow.lab' > /var/www/www1/index.html
echo '33 - www2.yellow.lab' > /var/www/www2/index.html
echo '33 - secure.yellow.lab' > /var/www/secure/index.html

mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.bak 2>/dev/null || true

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak

sed -i '/^Listen /d' /etc/httpd/conf/httpd.conf
cat >> /etc/httpd/conf/httpd.conf <<'EOF'
Listen 172.16.30.33:80
Listen 172.16.32.33:443
EOF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/secure.yellow.lab.key \
  -out /etc/pki/tls/certs/secure.yellow.lab.crt \
  -subj '/CN=secure.blue33.lab'

cat > /etc/httpd/conf.d/www1.conf <<'EOF'
<VirtualHost 172.16.30.33:80>
    ServerName www1.yellow.lab
    DocumentRoot /var/www/www1
    ErrorLog logs/www1-error_log
    CustomLog logs/www1-access_log combined
</VirtualHost>
EOF

cat > /etc/httpd/conf.d/www2.conf <<'EOF'
<VirtualHost 172.16.30.33:80>
    ServerName www2.yellow.lab
    DocumentRoot /var/www/www2
    ErrorLog logs/www2-error_log
    CustomLog logs/www2-access_log combined
</VirtualHost>
EOF

cat > /etc/httpd/conf.d/secure.conf <<'EOF'
<VirtualHost 172.16.32.33:443>
    ServerName secure.yellow.lab
    DocumentRoot /var/www/secure
    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/secure.yellow.lab.crt
    SSLCertificateKeyFile /etc/pki/tls/private/secure.yellow.lab.key
    ErrorLog logs/secure-error_log
    CustomLog logs/secure-access_log combined
</VirtualHost>
EOF

restorecon -R /var/www

httpd -t
systemctl enable httpd
systemctl restart httpd
systemctl status httpd --no-pager

--------
### On CLT
curl http://www1.yellow.lab
curl http://www2.yellow.lab
curl -k https://secure.yellow.lab

## Expected:

33 - www1.yellow.lab
33 - www2.yellow.lab
33 - secure.yellow.lab

That matches the major web requirement in the exam. 

---

## Step 8 — Advanced NFS

### On SRV

```bash
dnf install -y nfs-utils

mkdir -p /srv/nfs
chmod 755 /srv/nfs

cat > /etc/nfs.conf <<'EOF'
[nfsd]
vers3=y
vers4=y

[mountd]
port=20048

[statd]
port=32765
outgoing-port=32766
EOF

cat > /etc/exports <<'EOF'
/srv/nfs 172.16.31.0/24(rw,sync,no_root_squash)
/srv/nfs 172.16.30.0/24(ro,sync,no_root_squash)
EOF

# add the extra fixed statd ports to firewall
iptables -A INPUT -s 172.16.31.0/24 -p tcp --dport 32765 -j ACCEPT
iptables -A INPUT -s 172.16.31.0/24 -p udp --dport 32765 -j ACCEPT
iptables -A INPUT -s 172.16.31.0/24 -p tcp --dport 32766 -j ACCEPT
iptables -A INPUT -s 172.16.31.0/24 -p udp --dport 32766 -j ACCEPT
iptables -A INPUT -s 172.16.30.0/24 -p tcp --dport 32765 -j ACCEPT
iptables -A INPUT -s 172.16.30.0/24 -p udp --dport 32765 -j ACCEPT
iptables -A INPUT -s 172.16.30.0/24 -p tcp --dport 32766 -j ACCEPT
iptables -A INPUT -s 172.16.30.0/24 -p udp --dport 32766 -j ACCEPT

service iptables save

systemctl enable rpcbind nfs-server
systemctl restart rpcbind nfs-server
exportfs -arv
exportfs -v
```

### On CLT

```bash
dnf install -y nfs-utils
mkdir -p /mnt/nfs-rw
mount -t nfs 172.16.30.33:/srv/nfs /mnt/nfs-rw
echo 'Mustafa Jawish - 33' > /mnt/nfs-rw/ReadMe.nfs
ls -l /mnt/nfs-rw
cat /mnt/nfs-rw/ReadMe.nfs
```

### On SRV for the read-only proof

```bash
mkdir -p /mnt/nfs-ro
mount -t nfs 172.16.30.33:/srv/nfs /mnt/nfs-ro -o ro
cat /mnt/nfs-ro/ReadMe.nfs
touch /mnt/nfs-ro/testfile
```

The last `touch` should fail with read-only file system.
That is exactly what the exam wants for Advanced NFS. 

---


# Commands to create the script files for submission

You asked for the easiest way to create files so later you can copy them out of the VM.

Create them inside `/root/sba33`.

## On SRV

```bash
cd /root/sba33
```

### `setup_initial.sh`

```bash
cat > /root/sba33/setup_initial.sh <<'EOF'
#!/bin/bash
set -e
id lab >/dev/null 2>&1 || useradd -m lab
echo 'sba' | passwd --stdin lab
hostnamectl set-hostname jawo0004-SRV.yellow.lab
grep -q 'jawo0004-SRV.yellow.lab' /etc/hosts || cat >> /etc/hosts <<'EOT'
127.0.0.1   localhost localhost.localdomain
172.16.30.33 jawo0004-SRV.yellow.lab jawo0004-SRV
172.16.32.33 secure.yellow.lab
EOT
ip addr show ens192 | grep -q '172.16.32.33/24' || ip addr add 172.16.32.33/24 dev ens192
mkdir -p /home/lab/.ssh
chown -R final:lab /home/final
chmod 755 /home/lab
chmod 700 /home/lab/.ssh
EOF

chmod +x /root/sba33/setup_initial.sh
```

### `setup_firewall.sh`

```bash
cat > /root/sba33/setup_firewall.sh <<'EOF'
#!/bin/bash
set -e

iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# allow loopback
iptables -A INPUT -i lo -j ACCEPT

# allow established/related traffic
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# =========================================================
# SELECTED SERVICES ONLY
# =========================================================

# SSH (selected minor) -> allow only from client network
iptables -A INPUT -s 172.16.31.0/24 -p tcp --dport 22 -j ACCEPT

# Samba Public Share (selected minor) -> allow only from client network
iptables -A INPUT -s 172.16.31.0/24 -p tcp -m multiport --dports 139,445 -j ACCEPT
iptables -A INPUT -s 172.16.31.0/24 -p udp -m multiport --dports 137,138 -j ACCEPT

# Advanced Web Hosting (selected major) -> allow only from client network
iptables -A INPUT -s 172.16.31.0/24 -p tcp -m multiport --dports 80,443 -j ACCEPT

# Advanced NFS (selected major)
# RW from 172.16.31.0/24
# RO test from 172.16.30.0/24
for net in 172.16.31.0/24 172.16.30.0/24; do
  iptables -A INPUT -s $net -p tcp --dport 111 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 111 -j ACCEPT
  iptables -A INPUT -s $net -p tcp --dport 2049 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 2049 -j ACCEPT
  iptables -A INPUT -s $net -p tcp --dport 20048 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 20048 -j ACCEPT
  iptables -A INPUT -s $net -p tcp --dport 32765 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 32765 -j ACCEPT
  iptables -A INPUT -s $net -p tcp --dport 32766 -j ACCEPT
  iptables -A INPUT -s $net -p udp --dport 32766 -j ACCEPT
done

# =========================================================
# NOT SELECTED SERVICES
# =========================================================
# DNS   -> blocked by default DROP (53 tcp/udp not allowed)
# Mail  -> blocked by default DROP (25 tcp not allowed)
# LDAP  -> blocked by default DROP (389 tcp not allowed)
# Any other ports/services -> blocked by default DROP

service iptables save
systemctl enable iptables
systemctl restart iptables
EOF
chmod +x /root/sba33/setup_firewall.sh
```

### `setup_samba_public.sh`

```bash
cat > /root/sba33/setup_samba_public.sh <<'EOF'
#!/bin/bash
set -e

dnf install -y samba samba-client policycoreutils-python-utils

mkdir -p /srv/samba/public
chmod 0777 /srv/samba/public
chown nobody:nobody /srv/samba/public

cat > /etc/samba/smb.conf <<'EOT'
[global]
   workgroup = WORKGROUP
   server string = SBA Samba Server
   security = user
   map to guest = Bad User
   guest account = nobody

[samba-public]
   path = /srv/samba/public
   browseable = yes
   guest ok = yes
   guest only = yes
   read only = no
   writable = yes
   public = yes
   force user = nobody
   force group = nobody
   create mask = 0777
   directory mask = 0777
EOT

systemctl enable smb nmb
systemctl restart smb nmb

setsebool -P samba_export_all_rw on
semanage fcontext -a -t samba_share_t '/srv/samba/public(/.*)?' 2>/dev/null || \
semanage fcontext -m -t samba_share_t '/srv/samba/public(/.*)?'
restorecon -Rv /srv/samba/public

testparm
EOF

chmod +x /root/sba33/setup_samba_public.sh
```

### `setup_web_advanced.sh`

```bash
cat > /root/sba33/setup_web_advanced.sh <<'EOF'
#!/bin/bash
set -e

MAIN_IP="172.16.30.33"
ALIAS_IP="172.16.32.33"
DOMAIN="yellow.lab"

dnf install -y httpd mod_ssl

# make sure alias IP exists
ip addr show ens192 | grep -q "${ALIAS_IP}/24" || ip addr add ${ALIAS_IP}/24 dev ens192

mkdir -p /var/www/www1 /var/www/www2 /var/www/secure

echo '33 - www1.yellow.lab' > /var/www/www1/index.html
echo '33 - www2.yellow.lab' > /var/www/www2/index.html
echo '33 - secure.yellow.lab' > /var/www/secure/index.html

# move default ssl config away if present
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.bak 2>/dev/null || true

# remove old custom vhost files if rerun
rm -f /etc/httpd/conf.d/www1.conf /etc/httpd/conf.d/www2.conf /etc/httpd/conf.d/secure.conf

# clean Listen lines to avoid duplicate bind errors
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
sed -i '/^Listen /d' /etc/httpd/conf/httpd.conf
cat >> /etc/httpd/conf/httpd.conf <<EOT
Listen ${MAIN_IP}:80
Listen ${ALIAS_IP}:443
EOT

# create self-signed cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/secure.yellow.lab.key \
  -out /etc/pki/tls/certs/secure.yellow.lab.crt \
  -subj '/CN=secure.yellow.lab'

cat > /etc/httpd/conf.d/www1.conf <<EOT
<VirtualHost ${MAIN_IP}:80>
    ServerName www1.${DOMAIN}
    DocumentRoot /var/www/www1
    ErrorLog logs/www1-error_log
    CustomLog logs/www1-access_log combined
</VirtualHost>
EOT

cat > /etc/httpd/conf.d/www2.conf <<EOT
<VirtualHost ${MAIN_IP}:80>
    ServerName www2.${DOMAIN}
    DocumentRoot /var/www/www2
    ErrorLog logs/www2-error_log
    CustomLog logs/www2-access_log combined
</VirtualHost>
EOT

cat > /etc/httpd/conf.d/secure.conf <<EOT
<VirtualHost ${ALIAS_IP}:443>
    ServerName secure.${DOMAIN}
    DocumentRoot /var/www/secure
    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/secure.yellow.lab.crt
    SSLCertificateKeyFile /etc/pki/tls/private/secure.yellow.lab.key
    ErrorLog logs/secure-error_log
    CustomLog logs/secure-access_log combined
</VirtualHost>
EOT

restorecon -R /var/www

httpd -t
systemctl enable httpd
systemctl restart httpd
systemctl status httpd --no-pager

echo
echo "=== LOCAL TESTS ==="
curl -H 'Host: www1.yellow.lab' http://${MAIN_IP}
curl -H 'Host: www2.yellow.lab' http://${MAIN_IP}
curl -k --resolve secure.yellow.lab:443:${ALIAS_IP} https://secure.yellow.lab
EOF

chmod +x /root/sba33/setup_web_advanced.sh
```

### `setup_nfs_advanced.sh`

```bash
cat > /root/sba33/setup_nfs_advanced.sh <<'EOF'
#!/bin/bash
set -e
dnf install -y nfs-utils
mkdir -p /srv/nfs
chmod 755 /srv/nfs
cat > /etc/nfs.conf <<'EOT'
[nfsd]
vers3=y
vers4=y

[mountd]
port=20048

[statd]
port=32765
outgoing-port=32766
EOT
cat > /etc/exports <<'EOT'
/srv/nfs 172.16.31.0/24(rw,sync,no_root_squash)
/srv/nfs 172.16.30.0/24(ro,sync,no_root_squash)
EOT
systemctl enable rpcbind nfs-server
systemctl restart rpcbind nfs-server
exportfs -arv
EOF
chmod +x /root/sba33/setup_nfs_advanced.sh
```

## On CLT

### `setup_ssh_client.sh`

```bash
cat > /root/sba33/setup_ssh_client.sh <<'EOF'
#!/bin/bash
set -e
su - cst8246 -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
su - cst8246 -c '[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""'
echo 'Run these manually next:'
echo 'su - cst8246'
echo 'ssh-copy-id lab@172.16.30.33'
echo 'ssh-copy-id root@172.16.30.33'
EOF
chmod +x /root/sba33/setup_ssh_client.sh
```

### `test_services.sh`

```bash
cat > /root/sba33/test_services.sh <<'EOF'
#!/bin/bash
set -e

echo '=== SSH ==='
su - cst8246 -c "ssh -o StrictHostKeyChecking=no lab@172.16.30.33 'hostname'"
su - cst8246 -c "ssh -o StrictHostKeyChecking=no root@172.16.30.33 'hostname'"

echo '=== WEB ==='
curl http://www1.yellow.lab
curl http://www2.yellow.lab
curl -k https://secure.yellow.lab

echo '=== SAMBA ==='
dnf install -y cifs-utils >/dev/null 2>&1 || true
mkdir -p /mnt/samba-public
mountpoint -q /mnt/samba-public && umount /mnt/samba-public || true

mount -t cifs //172.16.30.33/samba-public /mnt/samba-public \
  -o guest,vers=3.0,uid=0,gid=0,file_mode=0777,dir_mode=0777

rm -f /mnt/samba-public/readme.smb
printf 'Mustafa Jawish - 33\n' | tee /mnt/samba-public/readme.smb >/dev/null
ls -l /mnt/samba-public
cat /mnt/samba-public/readme.smb

echo '=== NFS ==='
dnf install -y nfs-utils >/dev/null 2>&1 || true
mkdir -p /mnt/nfs-rw
mountpoint -q /mnt/nfs-rw && umount /mnt/nfs-rw || true

mount -t nfs 172.16.30.33:/srv/nfs /mnt/nfs-rw
printf 'Mustafa Jawish - 33\n' | tee /mnt/nfs-rw/ReadMe.nfs >/dev/null
ls -l /mnt/nfs-rw
cat /mnt/nfs-rw/ReadMe.nfs

echo '=== DONE ==='
EOF

chmod +x /root/sba33/test_services.sh
```

---

## Main script
cat > /root/sba33/main_setup.sh <<'EOF'
#!/bin/bash
set -e

cd /root/sba33

echo '=== STEP 1: INITIAL SETUP ==='
./setup_initial.sh

echo '=== STEP 2: FIREWALL ==='
./setup_firewall.sh

echo '=== STEP 3: SAMBA PUBLIC ==='
./setup_samba_public.sh

echo '=== STEP 4: ADVANCED WEB ==='
./setup_web_advanced.sh

echo '=== STEP 5: ADVANCED NFS ==='
./setup_nfs_advanced.sh

echo '=== SERVER SETUP COMPLETE ==='
EOF

chmod +x /root/sba33/main_setup.sh
'''' 


# Best run order for the scripts

## On SRV
cd /root/sba33
./main_setup.sh

## On CLT
cd /root/sba33
./setup_ssh_client.sh

Then manually:

su - cst8246
ssh-copy-id lab@172.16.30.33
ssh-copy-id root@172.16.30.33
exit

Then:

bash /root/sba33/test_services.sh
```
And for the NFS read-only proof on SRV:

mkdir -p /mnt/nfs-ro
mount -t nfs 172.16.30.33:/srv/nfs /mnt/nfs-ro -o ro
cat /mnt/nfs-ro/ReadMe.nfs
touch /mnt/nfs-ro/testfile
```




#cloud-config
# Cloud-init configuration for initial server setup

timezone: Europe/Paris
hostname: ${hostname}
fqdn: ${hostname}.${domain}
package_update: true
package_upgrade: true
package_reboot_if_required: true
ssh_pwauth: false
disable_root: false   # We will use sshd config to disable root login

disk_setup:
  /dev/sdb:
    table_type: gpt
    overwrite: false
    layout: [0]         # /, /home, /var/log, /data
fs_setup:
  - {label: data, filesystem: ext4, device: /dev/sdb1, overwrite: true}
mounts:
  - [/dev/sdb1, /data,        ext4, "defaults,noatime", 0, 2]

# Install essential packages
packages:
  - curl
  - wget
  - git
  - htop
  - iptables-persistent
  - fail2ban
  - unzip
  - vim

users:
  - default
  - name: ansible
    gecos: "Ansible automation account"
    groups: [sudo]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
    ssh_authorized_keys: ${ssh_public_keys}
  - name: ${admin_username}
    gecos: "Primary administrator"
    groups: [sudo]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
    ssh_authorized_keys: ${ssh_public_keys}


write_files:
  # SSH hardening (port + keys-only)
  - path: /etc/ssh/sshd_config.d/90-custom.conf
    owner: root:root
    permissions: '0644'
    content: |
      Port ${ssh_port}
      AddressFamily inet
      PermitRootLogin no
      PasswordAuthentication no
      ChallengeResponseAuthentication no
      AllowUsers ansible ${admin_username}

  # Fail2Ban jail for our custom SSH port
  - path: /etc/fail2ban/jail.d/ssh.conf
    owner: root:root
    permissions: '0644'
    content: |
      [sshd]
      enabled  = true
      port     = ${ssh_port}
      filter   = sshd
      logpath  = /var/log/auth.log
      maxretry = 3
      bantime  = 7200
      findtime = 1200
      action   = iptables[
                   name=%(__name__)s,
                   chain="DOCKER-USER",
                   port=${ssh_port},
                   protocol=tcp]

  # Initial iptables configuration
  - path: /etc/iptables/rules.v4
    owner: root:root
    permissions: '0644'
    content: |
      *filter
      :INPUT DENY [0:0]
      :FORWARD ACCEPT [0:0]
      :OUTPUT ACCEPT [0:0]
      :DOCKER-USER - [0:0]
      :ANSIBLE-SYSTEM - [0:0]
      
      # ANSIBLE-SYSTEM baseline chain
      -A ANSIBLE-SYSTEM -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
      -A ANSIBLE-SYSTEM -p tcp --dport ${ssh_port} -j ACCEPT
      
      # DOCKER-USER jumps to ANSIBLE-SYSTEM
      -A DOCKER-USER -j ANSIBLE-SYSTEM -m comment --comment "ansible-baseline"
      
      COMMIT


runcmd:
  # Apply iptables rules
  - iptables-restore < /etc/iptables/rules.v4
  # Restart services
  - systemctl restart ssh
  - systemctl enable --now fail2ban
  # Save iptables rules (will be automatically restored on boot by iptables-persistent)
  - netfilter-persistent save

final_message: |
  Cloud-init finished – connect with:
    ssh -p ${ssh_port} ${admin_username}@${hostname}.${domain}

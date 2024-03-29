data "template_file" "cloud_config" {
  count = var.servers

  template = <<-TEMPLATE
    #cloud-config
    preserve_hostname: false
    fqdn: ${module.hostname.fqdn[count.index]}
    hostname: ${module.hostname.name[count.index]}
    %{ if var.volume_size > 0 }
    mounts:
      - [ "LABEL=${digitalocean_volume.data_volume[count.index].filesystem_label}", "/srv", "xfs", "defaults", "0", "0" ]
    %{ endif }
    package_update: true
    package_upgrade: true
    packages:
      - rsync
      - sudo
      - rng-tools
    write_files:
      - content: |
          # Generated by terraform module. Do not edit manually!
          PermitRootLogin yes
          PubkeyAuthentication yes
          PasswordAuthentication no
          ChallengeResponseAuthentication no
          UsePAM yes
          X11Forwarding no
          PrintMotd no
          TCPKeepAlive yes
          ClientAliveInterval 15
          ClientAliveCountMax 3
          UseDNS no
          AcceptEnv LANG LC_*
          Subsystem sftp /usr/lib/openssh/sftp-server
        owner: root:root
        path: /etc/ssh/sshd_config
        permissions: '0644'
      - content: |
          # Generated by terraform module. Do not edit manually!
          net.ipv4.icmp_ratelimit = 100
          net.ipv4.icmp_ratemask = 88089
          net.ipv4.tcp_timestamps = 0
          net.ipv4.conf.all.arp_ignore = 1
          net.ipv4.conf.all.arp_announce = 2
          net.ipv4.tcp_rfc1337 = 1
          net.ipv4.conf.default.accept_redirects = 0
          net.ipv4.conf.all.accept_redirects = 0
          net.ipv6.conf.default.accept_redirects = 0
          net.ipv6.conf.all.accept_redirects = 0
          net.ipv4.conf.default.accept_source_route = 0
          net.ipv4.conf.all.secure_redirects = 0
          net.ipv4.conf.default.secure_redirects = 0
          net.ipv4.conf.all.send_redirects = 0
          net.ipv4.conf.default.send_redirects = 0
          net.ipv4.conf.all.log_martians = 1
          net.ipv4.conf.default.log_martians = 1
          net.ipv6.conf.default.router_solicitations = 0
          net.ipv6.conf.default.accept_ra_rtr_pref = 0
          net.ipv6.conf.default.accept_ra_pinfo = 0
          net.ipv6.conf.default.accept_ra_defrtr = 0
          net.ipv6.conf.all.accept_ra = 0
          net.ipv6.conf.default.accept_ra = 0
          net.ipv6.conf.default.autoconf = 0
          net.ipv6.conf.default.dad_transmits = 0
          net.ipv6.conf.default.max_addresses = 1
        owner: root:root
        path: /etc/sysctl.d/99-provisioner.conf
        permissions: '0644'
      - content: |
          # Generated by terraform module. Do not edit manually!
          install cramfs /bin/true
          install freevxfs /bin/true
          install jffs2 /bin/true
          install hfs /bin/true
          install hfsplus /bin/true
          install udf /bin/true
        owner: root:root
        path: /etc/modprobe.d/disable-uncommon-fs.conf
        permissions: '0644'
    users:
      - name: ${var.provisioner_username}
        groups:
          - adm
          - docker
          - sudo
        shell: /bin/bash
        homedir: ${var.provisioner_homedir}
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh_authorized_keys:
          - ${tls_private_key.provisioner[count.index].public_key_openssh}
    runcmd:
      - sysctl -p --system
      - rm -rf /etc/update-motd.d/99-one-click
      - ufw disable
      - systemctl restart sshd
      %{ if var.volume_size > 0 }
      - umount /dev/disk/by-label/${digitalocean_volume.data_volume[count.index].filesystem_label}
      - mount -a
      %{ endif }
  TEMPLATE
}

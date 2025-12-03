# NFS Server configuration (zcm03)
resource "null_resource" "nfs_server" {
  count = var.nfs_server_hostname == var.node_hostname ? 1 : 0

  triggers = {
    node_ip = var.node_ip
  }

  provisioner "remote-exec" {
    inline = [
      # Check if NFS server is already configured
      "if systemctl is-active --quiet nfs-kernel-server && grep -q '${var.nfs_export_base_path}' /etc/exports; then echo 'NFS server already configured, skipping setup'; exit 0; fi",

      # Install NFS server packages
      "apt-get update && apt-get install -y nfs-kernel-server",

      # Check if device exists and format /dev/sdb1 as ext4 if not already formatted
      "if [ -e /dev/sdb1 ]; then blkid /dev/sdb1 | grep -q ext4 || mkfs.ext4 /dev/sdb1; else echo 'Warning: /dev/sdb1 does not exist'; fi",

      # Create the export directory structure
      "mkdir -p ${var.nfs_export_base_path}",

      # Add entry to fstab for mounting /dev/sdb1 at boot time
      "grep -q '${var.nfs_export_base_path}' /etc/fstab || echo '/dev/sdb1 ${var.nfs_export_base_path} ext4 rw,user,exec,auto 0 0' >> /etc/fstab",

      # Mount the device if not already mounted and device exists
      "if [ -e /dev/sdb1 ]; then mount | grep -q '${var.nfs_export_base_path}' || mount /dev/sdb1 ${var.nfs_export_base_path}; fi",

      # Remount with new options if already mounted
      "if mount | grep -q '${var.nfs_export_base_path}'; then mount -o remount,rw,user,exec,auto ${var.nfs_export_base_path}; fi",

      # Create directories for each client node
      "mkdir -p ${var.nfs_export_base_path}/zcm01",
      "mkdir -p ${var.nfs_export_base_path}/zcm02",
      "mkdir -p ${var.nfs_export_base_path}/zcm03",
      "mkdir -p ${var.nfs_export_base_path}/zcm04",

      # Create directory for zcm03 and set permissions
      "mkdir -p ${var.nfs_export_base_path}/zcm03",
      "chown -R k3s:k3s ${var.nfs_export_base_path}/zcm03",
      "chmod -R 775 ${var.nfs_export_base_path}/zcm03",

      # Create /var/k3s directory and set permissions
      "mkdir -p /var/k3s",
      "chown -R k3s:k3s /var/k3s",
      "chmod -R 775 /var/k3s",

      # Set proper permissions for all users to have write access
      "chown -R nobody:nogroup ${var.nfs_export_base_path}",
      "chmod -R 777 ${var.nfs_export_base_path}",

      # Ensure the mount point has correct permissions even after reboot
      "if [ ! -f /etc/rc.local ]; then echo '#!/bin/bash' > /etc/rc.local; fi",
      "grep -q 'chmod -R 777 ${var.nfs_export_base_path}' /etc/rc.local || echo 'chmod -R 777 ${var.nfs_export_base_path}' >> /etc/rc.local",
      "chmod +x /etc/rc.local",

      # No need for sed command as we're adding the correct entry directly

      # Configure exports
      "echo '${templatefile("${path.module}/templates/exports.tpl", {
        export_base_path = var.nfs_export_base_path,
        client_nodes     = var.nfs_client_nodes,
        network_cidr     = var.network_cidr
      })}' > /etc/exports",

      # Apply exports configuration
      "exportfs -ra",

      # Ensure NFS server is running
      "systemctl enable nfs-kernel-server",
      "systemctl restart nfs-kernel-server",

      # Verify exports are working
      "showmount -e localhost"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      host        = var.node_ip
      port        = 22
      agent       = false
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

# NFS Client configuration (all nodes except the NFS server)
resource "null_resource" "nfs_client" {
  count = contains(var.nfs_client_nodes, var.node_hostname) ? 1 : 0

  triggers = {
    node_ip = var.node_ip
  }

  provisioner "remote-exec" {
    inline = [
      # Check if NFS client is already configured
      "if grep -q '${var.nfs_server_ip}:${var.nfs_export_base_path}/${var.node_hostname}' /etc/fstab && mount | grep -q '${var.nfs_client_mount_point}'; then echo 'NFS client already configured, skipping setup'; exit 0; fi",

      # Install NFS client packages (already installed in node module, but ensure it's here)
      "apt-get update && apt-get install -y nfs-common",

      # Create the mount point
      "mkdir -p ${var.nfs_client_mount_point}",

      # Wait for NFS server to be ready (retry a few times)
      "for i in {1..10}; do showmount -e ${var.nfs_server_ip} && break || sleep 5; done",

      # Add to fstab for persistent mounting
      "echo '${var.nfs_server_ip}:${var.nfs_export_base_path}/${var.node_hostname} ${var.nfs_client_mount_point} nfs defaults 0 0' >> /etc/fstab",

      # Mount the NFS share
      "mount ${var.nfs_client_mount_point}",

      # Verify the mount
      "df -h ${var.nfs_client_mount_point}"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      host        = var.node_ip
      port        = 22
      agent       = false
      private_key = file("~/.ssh/id_rsa")
    }
  }

  # Ensure the NFS server is configured before clients try to mount
  depends_on = [null_resource.nfs_server]
}

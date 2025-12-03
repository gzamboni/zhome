locals {
  # Find the node marked as "master" type in the nodes variable
  master_nodes    = { for node, data in var.nodes : node => data if data.type == "master" }
  master_hostname = keys(local.master_nodes)[0]
  master          = local.master_nodes[local.master_hostname]
  workers         = { for node, data in var.nodes : node => data if data.type != "master" }
}

resource "random_string" "cluster_token" {
  length  = 35
  special = false
}

resource "null_resource" "master_node" {
  provisioner "remote-exec" {
    inline = [
      # Check if K3s master is already configured
      "if systemctl is-active --quiet k3s && [ -f /etc/rancher/k3s/k3s.yaml ]; then echo 'K3s master node already configured, skipping setup'; exit 0; fi",

      # Add cgroup parameters to cmdline.txt if it's a Raspberry Pi
      "if [ -f /boot/firmware/cmdline.txt ]; then grep -q 'cgroup_memory=1 cgroup_enable=memory' /boot/firmware/cmdline.txt || sudo sed -i '$ s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/firmware/cmdline.txt; fi",

      # Add cgroup parameters to /etc/default/grub if it exists
      "if [ -f /etc/default/grub ]; then sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 cgroup_memory=1 cgroup_enable=memory\"/' /etc/default/grub && sudo update-grub; fi",

      # Install fuse-overlayfs package
      "sudo apt-get update && sudo apt-get install -y fuse-overlayfs",

      # Install k3s with data-dir set to /var/k3s and using fuse-overlayfs snapshotter
      "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=\"--data-dir /var/k3s --snapshotter=fuse-overlayfs\" sh -s - --write-kubeconfig-mode 644 --disable servicelb --token ${random_string.cluster_token.result} --node-ip ${local.master.ip} --disable-cloud-controller --disable local-storage"
    ]
    connection {
      type        = "ssh"
      user        = var.k3s_user
      private_key = var.ssh_key
      host        = local.master.ip
    }
  }
}

resource "null_resource" "worker_nodes" {
  for_each = local.workers
  provisioner "remote-exec" {
    inline = [
      # Check if K3s worker is already configured
      "if systemctl is-active --quiet k3s-agent; then echo 'K3s worker node already configured, skipping setup'; exit 0; fi",

      # Add cgroup parameters to cmdline.txt if it's a Raspberry Pi
      "if [ -f /boot/firmware/cmdline.txt ]; then grep -q 'cgroup_memory=1 cgroup_enable=memory' /boot/firmware/cmdline.txt || sudo sed -i '$ s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/firmware/cmdline.txt; fi",

      # Add cgroup parameters to /etc/default/grub if it exists
      "if [ -f /etc/default/grub ]; then sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 cgroup_memory=1 cgroup_enable=memory\"/' /etc/default/grub && sudo update-grub; fi",

      # Install fuse-overlayfs package
      "sudo apt-get update && sudo apt-get install -y fuse-overlayfs",

      # Install k3s with data-dir set to /var/k3s and using fuse-overlayfs snapshotter
      "curl -sfL https://get.k3s.io | K3S_URL=https://${local.master.ip}:6443 K3S_TOKEN=${random_string.cluster_token.result} INSTALL_K3S_EXEC=\"--data-dir /var/k3s --snapshotter=fuse-overlayfs\" sh -"
    ]
    connection {
      type        = "ssh"
      user        = var.k3s_user
      private_key = var.ssh_key
      host        = each.value.ip
    }
  }
  depends_on = [null_resource.master_node]
}

# Add K3s cluster to local kubeconfig
resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    on_failure = continue
    command    = <<-EOT
      # Check if kubeconfig already exists and is valid
      if [ -f ~/.kube/config-k3s ] && grep -q "${local.master.ip}" ~/.kube/config-k3s; then
        echo "K3s kubeconfig already configured, skipping setup"
        exit 0
      fi

      echo "Waiting for k3s to be ready..."
      for i in {1..10}; do
        if ssh -o StrictHostKeyChecking=no ${var.k3s_user}@${local.master.ip} "test -f /etc/rancher/k3s/k3s.yaml"; then
          echo "K3s config found, copying..."
          mkdir -p ~/.kube
          scp -o StrictHostKeyChecking=no ${var.k3s_user}@${local.master.ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config-k3s
          sed -i 's/127.0.0.1/${local.master.ip}/g' ~/.kube/config-k3s
          sed -i 's/: default/: k3s/g' ~/.kube/config-k3s
          echo "K3s config copied and updated."
          exit 0
        fi
        echo "K3s config not ready yet, waiting... (attempt $i/10)"
        sleep 10
      done
      echo "K3s config not available yet. You may need to reboot the nodes for cgroup changes to take effect."
      echo "After rebooting, run: ssh ${var.k3s_user}@${local.master.ip} 'sudo systemctl status k3s.service'"
      echo "Then run terraform apply again."
      exit 0
    EOT
  }
  depends_on = [null_resource.master_node]
}

# Merge kubeconfig files
resource "null_resource" "merge_kubeconfig" {
  provisioner "local-exec" {
    on_failure = continue
    command    = <<-EOT
      if [ -f ~/.kube/config-k3s ]; then
        # Check if config already contains k3s context
        if [ -f ~/.kube/config ] && grep -q "k3s" ~/.kube/config; then
          echo "K3s context already exists in kubeconfig, skipping merge"
          exit 0
        fi

        echo "Merging kubeconfig files..."
        cp -u ~/.kube/config ~/.kube/config.bkp 2>/dev/null || true
        if [ -f ~/.kube/config ]; then
          KUBECONFIG=~/.kube/config:~/.kube/config-k3s kubectl config view --flatten > ~/.kube/config-merged && mv -f ~/.kube/config-merged ~/.kube/config
        else
          cp ~/.kube/config-k3s ~/.kube/config
        fi
        echo "Kubeconfig files merged."
      else
        echo "K3s config not available, skipping merge."
      fi
      exit 0
    EOT
  }
  depends_on = [null_resource.kubeconfig]
}


# config kubernetes node labels by adding worker nodes to the cluster
# depends on right kubeconfig file being present and kubectl being installed
resource "null_resource" "node_labels" {
  provisioner "local-exec" {
    on_failure = continue
    command    = <<-EOT
      if [ -f ~/.kube/config ]; then
        # Check if nodes are already labeled
        LABELED_NODES=$(kubectl get nodes -l node-role.kubernetes.io/role=worker 2>/dev/null | grep -v "NAME" | wc -l)
        TOTAL_NODES=$(kubectl get nodes 2>/dev/null | grep -v "NAME" | wc -l)

        if [ $LABELED_NODES -gt 0 ] && [ $LABELED_NODES -eq $((TOTAL_NODES-1)) ]; then
          echo "Nodes are already labeled, skipping labeling"
          exit 0
        fi

        echo "Waiting for nodes to be ready..."
        for i in {1..30}; do
          NODES=$(kubectl get nodes 2>/dev/null | wc -l)
          if [ $NODES -gt 1 ]; then
            echo "Nodes are ready, applying labels..."
            for NODE in $(kubectl get nodes -o name | cut -d/ -f2); do
              echo "Labeling node $NODE..."
              kubectl label nodes $NODE node-role.kubernetes.io/role=worker node-type=worker --overwrite || echo "Failed to label node $NODE, will retry on next apply"
            done
            echo "Node labeling complete."
            exit 0
          fi
          echo "Nodes not ready yet, waiting... (attempt $i/30)"
          sleep 10
        done
        echo "Timed out waiting for nodes to be ready, will retry on next apply."
      else
        echo "Kubeconfig not available, skipping node labeling."
      fi
      exit 0
    EOT
  }
  depends_on = [null_resource.merge_kubeconfig]
}

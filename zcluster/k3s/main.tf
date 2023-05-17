locals {
  master  = [for node, data in var.nodes : data if data.type == "master"][0]
  workers = { for node, data in var.nodes : node => data if data.type == "worker" }
}

resource "random_string" "cluster_token" {
  length  = 35
  special = false
}

resource "null_resource" "master_node" {
  provisioner "remote-exec" {
    inline = ["curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable servicelb --token ${random_string.cluster_token.result} --node-ip ${local.master.ip} --disable-cloud-controller --disable local-storage"]
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
      "curl -sfL https://get.k3s.io | K3S_URL=https://${local.master.ip}:6443 K3S_TOKEN=${random_string.cluster_token.result} sh -"
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
    command = "mkdir -p ~/.kube && scp -o StrictHostKeyChecking=no ${var.k3s_user}@${local.master.ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config-k3s && sed -i 's/127.0.0.1/${local.master.ip}/g' ~/.kube/config-k3s && sed -i 's/: default/: k3s/g' ~/.kube/config-k3s"
  }
  depends_on = [null_resource.master_node]
}

# Merge kubeconfig files
resource "null_resource" "merge_kubeconfig" {
  provisioner "local-exec" {
    command = "cp -u ~/.kube/config ~/.kube/config.bkp && KUBECONFIG=~/.kube/config:~/.kube/config-k3s kubectl config view --flatten > ~/.kube/config-merged && mv -f ~/.kube/config-merged ~/.kube/config"
  }
  depends_on = [null_resource.kubeconfig]
}


# config kubernetes node labels by adding worker nodes to the cluster
# depends on right kubeconfig file being present and kubectl being installed
resource "kubernetes_labels" "worker_label" {
  for_each    = var.nodes
  api_version = "v1"
  kind        = "Node"
  metadata {
    name = each.key
  }
  labels = {
    "node-role.kubernetes.io/role" = "worker"
    "node-type"                    = "worker"
  }
  depends_on = [null_resource.merge_kubeconfig]
}

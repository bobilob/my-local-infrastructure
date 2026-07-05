terraform {
  # Här talar vi om vilka externa plugins (providers) Terraform behöver ladda ner
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.5.1"
    }
  }
}

# Initiera providern
provider "kind" {}

# Här definierar vi själva Kubernetes-klustret
resource "kind_cluster" "default" {
  name           = "mitt-devops-kluster"
  node_image     = "kindest/node:v1.29.2" # Definierar Kubernetes-versionen
  wait_for_ready = true

  # Vi bygger ett kluster med 1 Control Plane (Master) och 2 Workers
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}

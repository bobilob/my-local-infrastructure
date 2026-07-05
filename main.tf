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

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "my-demo-app"
    labels = {
      app = "my-demo-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "my-demo-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-demo-app"
        }
      }

      spec {
        container {
          image = "ghcr.io/bobilob/my-demo-app:latest"
          name  = "web"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app_service" {
  metadata {
    name = "my-demo-app-service"
  }

  spec {
    selector = {
      app = "my-demo-app"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

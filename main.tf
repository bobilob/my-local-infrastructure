terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.5.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Här definierar vi själva Kubernetes-klustret
resource "kind_cluster" "default" {
  name           = "mitt-devops-kluster"
  node_image     = "kindest/node:v1.29.2"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    # Vi sätter port-mappningen på första Workern istället för Control Plane!
    node {
      role = "worker"
      
      extra_port_mappings {
        container_port = 80
        host_port      = 8080
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 8443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }
  }
}

# Vår Deployment för appen
resource "kubernetes_deployment_v1" "app" {
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

# Nätverkskopplingen till appen
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

# Installera NGINX Ingress Controller via Helm (Standard NodePort-inställning för Kind)
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.hostPort.enabled"
    value = "true"
  }

  depends_on = [kind_cluster.default]
}

# Regeln som lyssnar efter din lokala domän
resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name = "my-demo-app-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "my-demo-app.local"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "my-demo-app-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.nginx_ingress]
}

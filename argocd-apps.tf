
# 1 Microservices demo

# 1.1 Microservices demo namespace
resource "kubernetes_namespace" "microservices_demo_namespace" {
  metadata {
    name = "microservices-demo"
	annotations = {
      "scheduler.alpha.kubernetes.io/node-selector" = "node-role=workload"
    }
  }
}

# 1.2. Microservices demo project
resource "argocd_project" "microservices_demo_project" {
  metadata {
    name = "microservices-demo-project"
    namespace = kubernetes_namespace.microservices_demo_namespace.metadata[0].name
  }

  spec {
    description = "Microservices demo project"

    source_repos = [
	  "https://github.com/GoogleCloudPlatform/microservices-demo.git"
	]
	
	destination {
      server = "https://kubernetes.default.svc"
      namespace = "microservices-demo"
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
  
  depends_on = [
    kubernetes_ingress_v1.otus_k8s_platform_argo_cd_ingress
  ]
}

# 1.3. Microservices demo application
resource "argocd_application" "microservices_demo_app" {
  metadata {
    name = "microservices-demo-app"
    namespace = "argo-cd"
  }
  spec {
    project = argocd_project.microservices_demo_project.metadata[0].name
    source {
      repo_url = "https://github.com/GoogleCloudPlatform/microservices-demo.git"
      target_revision = "HEAD"
      path = "helm-chart"
      helm {
        value_files = [file("./helm/microservices-demo-values.yaml")]
      }
    }
    destination {
      server = "https://kubernetes.default.svc"
      namespace = kubernetes_namespace.microservices_demo_namespace.metadata[0].name
    }
    sync_policy {
      automated {
        prune = true
        self_heal = true
      }
    }
  }
}

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
resource "kubernetes_manifest" "microservices_demo_project" {
  manifest = yamldecode(file("./argocd-apps/microservices-demo-appproject.yaml"))
  
  depends_on = [
    helm_release.otus_k8s_platform_argo_cd,
    kubernetes_namespace.microservices_demo_namespace
  ]
}

# 1.3. Microservices demo application
resource "kubernetes_manifest" "microservices_demo_app" {
  manifest = yamldecode(file("./argocd-apps/microservices-demo-application.yaml"))
  
  depends_on = [
    kubernetes_manifest.microservices_demo_project
  ]
}

# 1.4 Grafana ingress
resource "kubernetes_ingress_v1" "microservices_demo_ingress" {
  metadata {
    name = "microservices-demo-ingress"
	namespace = "microservices-demo"
  }
  
  depends_on = [
    helm_release.otus_k8s_platform_ingress_nginx,
    kubernetes_manifest.microservices_demo_app
  ]

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "microservices-demo.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "frontend"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
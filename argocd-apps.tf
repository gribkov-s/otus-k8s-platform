
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
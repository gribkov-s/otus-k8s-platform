
# Создание kubeconfig
resource "null_resource" "generate_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
      yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.otus_k8s_platform_cluster.id} --external --kubeconfig=./kubeconfig.yaml --force
    EOT
  }

  depends_on = [
	yandex_kubernetes_cluster.otus_k8s_platform_cluster
  ]
}

# 1. Ingress контроллер
resource "helm_release" "otus_k8s_platform_ingress_nginx" {
  name = "otus-k8s-platform-ingress-nginx"
  namespace = "ingress-nginx"
  repository = "oci://registry-1.docker.io/bitnamicharts"    
  chart = "nginx-ingress-controller"
  
  atomic = true
  create_namespace = true
  values = [templatefile("./helm/ingress-values.yaml", {
    ingress_ip = yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address
  })]
  
  depends_on = [
    yandex_kubernetes_node_group.otus_k8s_platform_infra_node_group,
	yandex_vpc_address.otus_k8s_platform_ingress_ip,
	null_resource.generate_kubeconfig
  ]
}

# 2. ArgoCD
resource "helm_release" "otus_k8s_platform_argo_cd" {
  name = "otus-k8s-platform-argo-cd"
  namespace = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"    
  chart = "argo-cd"
  
  atomic = true
  create_namespace = true
  values = [file("./helm/argocd-values.yaml")]
  
  depends_on = [
    helm_release.otus_k8s_platform_ingress_nginx
  ]
}

# 2.1 ArgoCD ingress
resource "kubernetes_ingress_v1" "otus_k8s_platform_argo_cd_ingress" {
  metadata {
    name = "otus-k8s-platform-argo-cd-ingress"
	namespace = "argo-cd"
	# annotations = {
      # "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      # "nginx.ingress.kubernetes.io/ssl-passthrough" = "true"
    # }
  }
  
  depends_on = [
    helm_release.otus_k8s_platform_argo_cd
  ]

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "argocd.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "otus-k8s-platform-argo-cd-argocd-server"
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

# http://argocd.sgribkov.158.160.49.193.nip.io


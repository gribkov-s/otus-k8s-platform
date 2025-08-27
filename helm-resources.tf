
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

# 2.1 ArgoCD release
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

# 2.2 ArgoCD ingress
resource "kubernetes_ingress_v1" "otus_k8s_platform_argo_cd_ingress" {
  metadata {
    name = "otus-k8s-platform-argo-cd-ingress"
	namespace = "argo-cd"
  }
  
  depends_on = [
    helm_release.otus_k8s_platform_ingress_nginx,
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
# user: admin
# password: otus2025$

# 3. Логирование

# 3.1 Loki
resource "helm_release" "otus_k8s_platform_loki" {
  name = "otus-k8s-platform-loki"
  namespace = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart = "loki"

  atomic = true
  create_namespace = true
  
  values = [templatefile("./helm/loki-values.yaml", {
    bucket_name = yandex_storage_bucket.otus_k8s_platform_logs_storage.bucket
	access_key_id = yandex_iam_service_account_static_access_key.otus_k8s_platform_logs_storage_sa_access.access_key
	secret_access_key = yandex_iam_service_account_static_access_key.otus_k8s_platform_logs_storage_sa_access.secret_key
  })]
  
  depends_on = [
    yandex_kubernetes_node_group.otus_k8s_platform_infra_node_group
  ]
}

# 3.2 Promtail
resource "helm_release" "otus_k8s_platform_promtail" {
  name = "otus-k8s-platform-promtail"
  namespace = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart = "promtail"

  atomic = true
  create_namespace = true
  values = [file("./helm/promtail-values.yaml")]

  depends_on = [
    helm_release.otus_k8s_platform_loki
  ]
}

# 4. Мониторинг

# 4.1 Prometheus

# 4.2 ???

# 5. Grafana

# 5.1 Grafana release
resource "helm_release" "otus_k8s_platform_grafana" {
  name = "otus-k8s-platform-grafana"
  namespace = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart = "grafana"

  atomic = true
  create_namespace = true
  values = [file("./helm/grafana-values.yaml")]

  depends_on = [
	# helm_release.otus_k8s_platform_prometheus,
	helm_release.otus_k8s_platform_loki
  ]
}

# 5.2 Grafana ingress
resource "kubernetes_ingress_v1" "otus_k8s_platform_grafana_ingress" {
  metadata {
    name = "otus-k8s-platform-grafana-ingress"
	namespace = "grafana"
  }
  
  depends_on = [
    helm_release.otus_k8s_platform_ingress_nginx,
    helm_release.otus_k8s_platform_grafana
  ]

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "grafana.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "otus-k8s-platform-grafana"
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

# http://grafana.sgribkov.158.160.49.193.nip.io
# user: admin
# password: 9Z8dZbI30NVlBs1KonRljRJUdn28h3ct4calIfip



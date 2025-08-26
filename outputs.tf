output "otus_k8s_platform_kubernetes_cluster_endpoint" {
  value = yandex_kubernetes_cluster.otus_k8s_platform_cluster.master[0].external_v4_endpoint
}

output "otus_k8s_platform_kubernetes_cluster_id" {
  value = yandex_kubernetes_cluster.otus_k8s_platform_cluster.id
}

output "otus_k8s_platform_agrocd_host" {
  value = "argocd.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
}

output "otus_k8s_platform_grafana_host" {
  value = "grafana.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
}

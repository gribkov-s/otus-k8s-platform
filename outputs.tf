output "otus_k8s_platform_kubernetes_cluster_endpoint" {
  value = yandex_kubernetes_cluster.otus_k8s_platform_cluster.master[0].external_v4_endpoint
  description = "otus k8s platform kubernetes cluster endpoint"
}

output "otus_k8s_platform_kubernetes_cluster_id" {
  value = yandex_kubernetes_cluster.otus_k8s_platform_cluster.id
  description = "otus k8s platform kubernetes cluster id"
}

output "otus_k8s_platform_agrocd_url" {
  value = "http://argocd.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
  description = "otus k8s platform agrocd url"
}

output "otus_k8s_platform_grafana_url" {
  value = "http://grafana.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
  description = "otus k8s platform grafana url"
}

output "otus_k8s_platform_prometheus_url" {
  value = "http://prometheus.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
  description = "otus k8s platform prometheus url"
}

output "otus_k8s_platform_alertmanager_url" {
  value = "http://alertmanager.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
  description = "otus k8s platform alertmanager url"
}

output "otus_k8s_platform_app_microservices_demo_url" {
  value = "http://microservices-demo.sgribkov.${yandex_vpc_address.otus_k8s_platform_ingress_ip.external_ipv4_address[0].address}.nip.io"
  description = "otus k8s platform app microservices demo url"
}

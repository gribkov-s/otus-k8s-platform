
# 1. Виртуальная сеть (VPC)
resource "yandex_vpc_network" "otus_k8s_platform_network" {
  name = "otus-k8s-platform-network"
}

# 2. Подсеть
resource "yandex_vpc_subnet" "otus_k8s_platform_subnet" {
  name           = "otus-k8s-platform-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.otus_k8s_platform_network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# 3. Группа безопасности (облачный файрвол)
resource "yandex_vpc_security_group" "k8s_sg" {
  name       = "k8s-security-group"
  network_id = yandex_vpc_network.otus_k8s_platform_network.id

  # Правило, разрешающее весь трафик внутри этой группы безопасности.
  ingress {
    protocol          = "ANY"
    description       = "Правило для внутрикластерного взаимодействия"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  # Правило, разрешающее балансировщику проверять здоровье узлов.
  ingress {
    protocol          = "TCP"
    description       = "Правило для проверок здоровья от балансировщика"
    predefined_target = "loadbalancer_healthchecks"
  }

  # Правило для доступа к API Kubernetes извне
  ingress {
    protocol       = "TCP"
    description    = "Правило для kubectl"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  # Дополнительное правило для доступа к API Kubernetes извне
  ingress {
    protocol       = "TCP"
    description    = "Правило для kubectl"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9443
  }

  # Правило для доступа по SSH
  ingress {
    protocol       = "TCP"
    description    = "Правило для доступа по SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Правило для сервисов Kubernetes (NodePort)
  ingress {
    protocol       = "TCP"
    description    = "Правило для сервисов Kubernetes (NodePort)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешаем любой исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Кластер Kubernetes
resource "yandex_kubernetes_cluster" "otus_k8s_platform_cluster" {
  name       = "otus-k8s-platform-cluster"
  network_id = yandex_vpc_network.otus_k8s_platform_network.id
  master {
    zonal {
      zone      = yandex_vpc_subnet.otus_k8s_platform_subnet.zone
      subnet_id = yandex_vpc_subnet.otus_k8s_platform_subnet.id
    }
    public_ip = true
    version   = "1.32"
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
  }
  service_account_id      = "aje9vi5rp1o6c94ndoa5"
  node_service_account_id = "aje9vi5rp1o6c94ndoa5"
}

# 5. Группа узлов для инфраструктуры
resource "yandex_kubernetes_node_group" "otus_k8s_platform_infra_node_group" {
  name       = "otus-k8s-platform-infra-node-group"
  cluster_id = yandex_kubernetes_cluster.otus_k8s_platform_cluster.id
  version    = "1.32"
  
  instance_template {
    platform_id = "standard-v3"
    boot_disk {
      type = "network-hdd"
      size = 32
    }
    resources {
      memory = 2
      cores  = 2
    }
    container_runtime {
      type = "containerd"
    }
    network_interface {
      subnet_ids         = [yandex_vpc_subnet.otus_k8s_platform_subnet.id]
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
      nat                = true
    }
    metadata = {
      ssh-keys = "ubuntu:${file("./keys/ssh_node_group_key.pub")}"
    }
  }
  
  scale_policy {
    fixed_scale {
      size = 3
    }
  }
  
  node_labels = {
    "node-role" = "infra"
  }
  
  node_taints = [
    "node-role=infra:NoSchedule"
  ]
}

# 6. Группа узлов для приложений
resource "yandex_kubernetes_node_group" "otus_k8s_platform_workload_node_group" {
  name       = "otus-k8s-platform-workload-node-group"
  cluster_id = yandex_kubernetes_cluster.otus_k8s_platform_cluster.id
  version    = "1.32"
  
  instance_template {
    platform_id = "standard-v3"
    boot_disk {
      type = "network-hdd"
      size = 32
    }
    resources {
      memory = 4
      cores  = 4
    }
    container_runtime {
      type = "containerd"
    }
    network_interface {
      subnet_ids         = [yandex_vpc_subnet.otus_k8s_platform_subnet.id]
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
      nat                = true
    }
    metadata = {
      ssh-keys = "ubuntu:${file("./keys/ssh_node_group_key.pub")}"
    }
  }
  
  scale_policy {
    fixed_scale {
      size = 1
    }
  }
  
  node_labels = {
    "node-role" = "workload"
  }
}

# 7. IP адрес для Ingress
resource "yandex_vpc_address" "otus_k8s_platform_ingress_ip" {
  name = "otus-k8s-platform-ingress-ip"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

# 8. Хранилище логов

# 8.1 Access_key для доступа к хранилищу
resource "yandex_iam_service_account_static_access_key" "otus_k8s_platform_logs_storage_sa_access" {
  service_account_id = "aje9vi5rp1o6c94ndoa5" # yandex_iam_service_account.otus_k8s_platform_logs_storage_sa.id
}

# 8.2 Storage bucket
resource "yandex_storage_bucket" "otus_k8s_platform_logs_storage" {
  bucket = "otus-k8s-platform-logs-storage"
  access_key = yandex_iam_service_account_static_access_key.otus_k8s_platform_logs_storage_sa_access.access_key
  secret_key = yandex_iam_service_account_static_access_key.otus_k8s_platform_logs_storage_sa_access.secret_key

  anonymous_access_flags {
    read = false
    list = false
  }
}
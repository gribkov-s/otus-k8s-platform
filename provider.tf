terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
	  version = ">= 0.13"
    }
	helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17"
    }
  }
}

provider "yandex" {
  zone = "ru-central1-d"
  folder_id = "b1gubdlu280spmf567hl"
  service_account_key_file = "./keys/key.json"
}

provider "helm" {
  kubernetes = {
    config_path = "${path.module}/kubeconfig.yaml"
  }
}

provider "kubernetes" {
  config_path = "${path.module}/kubeconfig.yaml"
}
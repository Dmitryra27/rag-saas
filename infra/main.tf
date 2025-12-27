terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.177.0"
    }
  }
}

provider "yandex" {
  # Используем IAM-токен через yc CLI (рекомендуется)
  # → Terraform будет брать токен из yc config автоматически
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

# Сеть
resource "yandex_vpc_network" "main" {
  name = "rag-net"
}

resource "yandex_vpc_subnet" "main" {
  name           = "rag-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Service Account для Kubernetes
resource "yandex_iam_service_account" "k8s" {
  name = "k8s-sa"
}

# Роли для Service Account
resource "yandex_resourcemanager_cloud_iam_member" "k8s-editor" {
  cloud_id = var.yc_cloud_id
  role     = "editor"
  member   = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Kubernetes кластер
resource "yandex_kubernetes_cluster" "main" {
  name        = "rag-cluster"
  description = "RAG SaaS Kubernetes cluster"

  network_id = yandex_vpc_network.main.id
  master {
    version = "1.29"
    zonal {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.main.id
    }
    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id

  release_channel = "RAPID"
}

# Узлы Kubernetes
resource "yandex_kubernetes_node_group" "main" {
  cluster_id = yandex_kubernetes_cluster.main.id
  version    = "1.29"
  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 4
      cores  = 2
    }
    boot_disk {
      type = "network-ssd"
      size = 30
    }
    network_interface {
      subnet_ids = [yandex_vpc_subnet.main.id]
      nat        = true
    }
  }
  scale_policy {
    fixed {
      size = 2
    }
  }
}

# Managed PostgreSQL
resource "yandex_mdb_postgresql_cluster" "main" {
  name        = "rag-pg"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id
  version     = "15"

  config {
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 10
    }
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.main.id
  }

  database {
    name = "rag_db"
  }

  user {
    name     = "rag_user"
    password = var.pg_password
    permission {
      database_name = "rag_db"
    }
  }
}

# Lockbox для секретов
resource "yandex_lockbox_secret" "rag" {
  name = "rag-secrets"
}

resource "yandex_lockbox_secret_version" "rag" {
  secret_id = yandex_lockbox_secret.rag.id
  entries {
    key   = "GIGACHAT_CLIENT_ID"
    text  = var.gigachat_client_id
  }
  entries {
    key   = "GIGACHAT_SECRET"
    text  = var.gigachat_secret
  }
  entries {
    key   = "YC_API_KEY"
    text  = var.yc_api_key
  }
  entries {
    key   = "JWT_SECRET"
    text  = var.jwt_secret
  }
}

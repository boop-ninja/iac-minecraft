variable base_name {
  default = "minecraft"
  description = "The base name of the modpack"
}

variable namespace {
  default = "minecraft-server"
  description = "The namespace of the modpack"
}

variable pvc_storage_class_name {
  default = "longhorn"
  description = "The name of the PVC storage class to use"
}

variable pvc_requests {
  default = "20G"
  description = "The PVC requested size"
}

resource kubernetes_persistent_volume_claim server_pvc {
  metadata {
    name = "${var.base_name}-server-pv-claim"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = var.pvc_storage_class_name
    resources {
      requests = {
        storage = var.pvc_requests
      }
    }
  }
}

variable server_image {
  default = "itzg/minecraft-server:java16"
  description = "The image to use for the server"
}

variable environment_vars {
  default = {}
  description = "Environment variables to set"
}

variable additional_ports {
  default = []
  description = "Additional ports to expose"
}

variable use_database {
  default = false
  description = "Whether or not to attach a database container"
}

variable database_container_name {
  default = "postgresql"
  description = "The name of the database container"
}

variable database_container_image {
  default = "postgres:14"
  description = "The image to use for the database"
}

variable database_container_mount_path {
  default = "/var/lib/postgresql/data/"
  description = "The mount path for the database"
}

variable database_config {
  default = {
    "POSTGRES_PASSWORD": "changeme",
    "POSTGRES_USER": "minecraft",
    "POSTGRES_DB": "minecraft",
  }
  description = "The configuration to use for the database"
}

locals {
  persistent_volume_name = "${var.base_name}-server-persistent-storage"
  environment_vars = merge({
    "EULA" = "TRUE"
    "TYPE" = "PAPER"
    "MAX_PLAYERS" = "20"
    "ONLINE_MODE" = "TRUE"
    "RCON_PORT" = "25575"
    "RCON_PASSWORD" = "changeme"
    "USE_AIKAR_FLAGS" = "TRUE"
    "SERVER_NAME" = var.base_name
    "ENABLE_COMMAND_BLOCK" = "TRUE"
    "SERVER_MOTD" = "A Minecraft Server"
    "INIT_MEMORY" = "2G"
    "MAX_MEMORY" = "4G"
  }, var.environment_vars)
  database_container = {
    name = var.database_container_name
    image = var.database_container_image
    data_mount_path = var.database_container_mount_path
    environment_vars = merge({
      "POSTGRES_PASSWORD" = "changeme"
      "POSTGRES_USER" = "minecraft"
      "POSTGRES_DB" = "minecraft"
    }, var.database_config)
  }
}

output persistent_volume_name {
  value       = kubernetes_persistent_volume_claim.server_pvc.metadata[0].name
  sensitive   = false
  description = "Name of the storage volume claim"
  depends_on  = [kubernetes_persistent_volume_claim.server_pvc]
}


data "kubernetes_persistent_volume_claim" "server_pvc" {
  metadata {
    name = "${var.base_name}-server-pv-claim"
    namespace = var.namespace
  }
}

resource kubernetes_deployment server_deployment {
  metadata {
    name = "${var.base_name}-server"
    namespace = var.namespace
    labels = {
      app = "${var.base_name}-server"
      designation = "server"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "${var.base_name}-server"
        designation = "server"
      }
    }
    template {
      metadata {
        namespace = var.namespace
        labels = {
          app = "${var.base_name}-server"
          designation = "server"
        }
      }
      spec {
        container {
          name = "${var.base_name}-server"
          image = var.server_image
          image_pull_policy = "Always"
          resources {
             limits = {
                cpu = "1000m"
                memory = local.environment_vars["MAX_MEMORY"]
              }
            }
          dynamic "env" {
            for_each = local.environment_vars
            content {
              name = env.key
              value = env.value
            }
          }
          port {
            name = "join"
            container_port = 25565
          }
          port {
            name = "rcon"
            container_port = 25575
          }
          dynamic "port" {
            for_each = var.additional_ports
            content {
              container_port = port.value.container_port
              name = port.value.name
            }
          }
          volume_mount {
            name = local.persistent_volume_name
            mount_path = "/data"
          }
        }
        dynamic "container" {
          for_each = var.use_database ? [local.database_container.name] : []
          content {
            name = local.database_container.name
            image = local.database_container.image
            image_pull_policy = "Always"
            resources {
             limits = {
                cpu = "100m"
                memory = "128Mi"
              }
            }
            volume_mount {
              name = local.persistent_volume_name
              mount_path =  local.database_container.data_mount_path
              sub_path = "${local.database_container.name}-data"
            }
            dynamic "env" {
              for_each = local.database_container.environment_vars
              content {
                name = env.key
                value = env.value
              }
            }
          }
        }
        volume {
          name = local.persistent_volume_name
          persistent_volume_claim {
            claim_name = data.kubernetes_persistent_volume_claim.server_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

variable external_ip {
  type = string
  description = "The external IP address of the server"
}

resource kubernetes_service server_service {
  depends_on = [kubernetes_deployment.server_deployment]
  metadata {
    name = "${var.base_name}-server"
    namespace = var.namespace
    labels = {
      app = "${var.base_name}-server"
      designation = "server"
    }
  }
  spec {
    selector = {
      app = "${var.base_name}-server"
      designation = "server"
    }
    external_ips = [var.external_ip]
    port {
      port = 25565
      target_port = 25565
    }
  }
}




variable namespace {
  description = "Namespace"
  type = string
}

variable persistent_volume_name {
  description = "The name of the persistent volume to mount."
  type = string
}

data kubernetes_persistent_volume_claim pvc {
  metadata {
    name = var.persistent_volume_name
    namespace = var.namespace
  }
}

data "local_file" "Caddyfile" {
    filename = "${path.module}/configs/Caddyfile"
}

resource kubernetes_config_map config {
  metadata {
    name = "caddy-config"
    namespace = var.namespace
  }
  data = {
    Caddyfile = data.local_file.Caddyfile.content
  }
}

resource kubernetes_service bluemaps_live_service {
  metadata {
    name = "minecraft-bluemaps-live"
    namespace = var.namespace
    labels = {
      app = "minecraft-bluemaps"
      designation = "web"
    }
  }
  spec {
    selector = {
      app = "minecraft-server"
      designation = "server"
    }
    port {
      name = "bluemaps"
      port = 80
      target_port = "bluemaps"
    }
  }
}

resource kubernetes_deployment deployment {
  depends_on = [
    data.kubernetes_persistent_volume_claim.pvc,
    kubernetes_service.bluemaps_http_service,
    kubernetes_config_map.config,
  ]
  metadata {
    name = "bluemaps"
    namespace = var.namespace
    labels = {
      app = "bluemaps"
      designation = "caddy"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "bluemaps"
        designation = "caddy"
      }
    }
    template {
      metadata {
        namespace = var.namespace
        labels = {
          app = "bluemaps"
          designation = "caddy"
        }
      }
      spec {
        container {
          name = "caddy"
          image = "caddy"
          image_pull_policy = "Always"
          working_dir = "/usr/share/caddy"

          resources {
            limits = {
              cpu = "100m"
              memory = "128Mi"
            }
          }

          port {
            name = "web"
            container_port = 8080
          }
          volume_mount {
            name = var.persistent_volume_name
            mount_path = "/usr/share/caddy/"
            sub_path = "bluemap/web"
          }
          volume_mount {
            name = "config"
            mount_path = "/etc/caddy/Caddyfile"
            sub_path = "Caddyfile"
          }
        }
        volume {
          name = var.persistent_volume_name
          persistent_volume_claim {
            claim_name = var.persistent_volume_name
          }
        }
        volume {
          name = "config"
          config_map {
            name = "caddy-config"
          }
        }
      }
    }
  }
}

resource kubernetes_service bluemaps_http_service {
  metadata {
    name = "minecraft-bluemaps-http"
    namespace = var.namespace
    labels = {
      app = "minecraft-bluemaps"
      designation = "web"
    }
  }
  spec {
    selector = {
      app = "bluemaps"
      designation = "caddy"
    }
    port {
      name = "bluemaps"
      port = 80
      target_port = "web"
    }
  }
}

variable domain {
  description = "The name of the server to create."
} 

resource kubernetes_ingress bluemaps {
  metadata {
    name = "minecraft-bluemaps-http"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
    labels = {
      app = "minecraft-bluemaps"
      designation = "web"
    }
  }
  spec {
    rule {
      host = var.domain
      http {
        path {
          backend {
            service_name = "minecraft-bluemaps-http"
            service_port = "bluemaps"
          }
        }
      }
    }
    tls {
      secret_name = kubernetes_secret.tls.metadata[0].name
    }
  }
}

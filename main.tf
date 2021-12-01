variable "kubernetes_namespace" {
  default     = "minecraft-server"
  description = "The namespace to deploy the server to"
}


locals {
  labels = {
    name = "minecraft-server",
  }
}

resource "kubernetes_namespace" "i" {
  metadata {
    name   = var.kubernetes_namespace
    labels = local.labels
  }
}

variable "mods" {
  default     = []
  description = "The mods to install"
}

variable "additional_ports" {
  default     = []
  description = "Additional ports to expose"
}

variable "environment_vars" {
  default     = {}
  description = "Environment variables to set"
}

variable "use_database" {
  default     = false
  description = "Whether to use a database"
}

variable "database_password" {
  default     = "password"
  description = "The password for the database"
}

variable external_ip  {
  description = "The external IP address of the server"
}

module "base" {
  source    = "./modules/server"
  namespace = var.kubernetes_namespace

  # Connection details
  external_ip = var.external_ip

  # Server Configurations
  environment_vars = merge({
    MODS = join(" ", var.mods)
  }, var.environment_vars)
  additional_ports = var.additional_ports

  # Database Configurations
  use_database = var.use_database
  database_config = {
    POSTGRES_PASSWORD = var.database_password
  }
}

variable domain {
  description = "The domain to use for the server"
}

module bluemaps {
  depends_on = [module.base]
  source = "./modules/bluemaps"
  domain = var.domain
  persistent_volume_name = module.base.persistent_volume_name
  namespace = var.kubernetes_namespace
}
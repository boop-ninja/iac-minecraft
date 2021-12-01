terraform {
  backend "kubernetes" {
    secret_suffix    = "minecraft-state"
    load_config_file = true
    namespace        = "terraform"
  }
}

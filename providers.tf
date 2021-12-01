variable "kube_host" {
  description = "Host of your kubernetes cluster"
}

variable "kube_crt" {
  default     = ""
  description = "Certificate of your kubernetes cluster"
}

variable "kube_key" {
  default     = ""
  description = "key of your kubernetes cluster"
}

provider "kubernetes" {
  host               = var.kube_host
  client_certificate = base64decode(var.kube_crt)
  client_key         = base64decode(var.kube_key)
  insecure           = true
}
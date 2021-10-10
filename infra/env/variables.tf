############################### shared
variable shared_rg_name {
    default = "<not set>"
} 

variable "shared_acr_name"{
  default = "<not set>"
}

variable "shared_sa_name"{
  default = "<not set>"
}
################################ main

variable "app" {
  default = "eshop"
}

variable "env" {
  default = "<not set>"
}

variable "prefix" {
  default = "<not set>"
}

variable "prefix_alphanum" {
  default = "<not set>"
}

variable "location" {
  default = "<not set>"
}

// clusters
variable "aks_tier" {
  default = "<not set>"
}

variable "aks_nodes" {
  default = 0
}
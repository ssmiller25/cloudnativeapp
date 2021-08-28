terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
    }
  }
}


# Configure the Civo Provider
provider "civo" {
  token = var.civo_token
  region = "NYC1"
}
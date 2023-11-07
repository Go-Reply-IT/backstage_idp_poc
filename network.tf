##############################
# Backstage Project Networking
##############################
module "backstage_vpc" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v27.0.0"
  project_id = module.backstage_project.project_id
  name       = "backstage-vpc"
  factories_config = {
    subnets_folder = "data/subnets/backstage"
  }
  delete_default_routes_on_create = true
  routes = {
    internet = {
      dest_range    = "0.0.0.0/0"
      priority      = 10000
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
  }
}

module "backstage_firewall_rules" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v27.0.0"
  project_id = module.backstage_project.project_id
  network    = module.backstage_vpc.name
  factories_config = {
    rules_folder = "./data/firewall/backstage"
  }
  default_rules_config = {
    disabled = true
  }
}

module "pga_dns" {
  source = "github.com/Go-Reply-IT/tf_modules//pga"
  project_id = module.backstage_project.project_id
  name       = "gke"
  domains = {
    artifact = true
    download = true
    packages = true
  }
  config = {
    private = true
  }
  networks = [
    module.backstage_vpc.self_link
  ]
}

############################
# Addresses
############################
module "addresses" {
  source           = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-address?ref=v27.0.0"
  project_id       = module.backstage_project.project_id
  global_addresses = ["ingress-backstage"]
  internal_addresses = {
    backstage-psc-ip = {
      address    = "10.0.0.42"
      region     = var.region
      subnetwork = module.backstage_vpc.subnet_self_links["${var.region}/backstage-db"]
      purpose    = "GCE_ENDPOINT"
    }
  }
}

# module "nat" {
#   source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v27.0.0"
#   project_id     = module.backstage_project.project_id
#   region         = var.region
#   name           = "default"
#   router_network = module.backstage_vpc.self_link
# }
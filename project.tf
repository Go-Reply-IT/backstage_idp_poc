##############################
# Backstage Project
##############################
module "backstage_project" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v27.0.0"
  name   = var.backstage_project
  services = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com"
  ]
  project_create = false
  skip_delete    = true
}
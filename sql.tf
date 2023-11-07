module "sql_instance" {
  source                    = "./modules/cloudsql-instance"
  project_id                = module.backstage_project.project_id
  name                      = "backstage-postgresql-db"
  region                    = var.region
  availability_type         = "REGIONAL"
  database_version          = "POSTGRES_15"
  tier                      = "db-custom-1-4096"
  psc_enabled               = true
  allowed_consumer_projects = [module.backstage_project.project_id]
  databases                 = ["backstage"]
  users = {
    backstage = null
  }
}

resource "google_compute_forwarding_rule" "psc_sql_instance" {
  project               = module.backstage_project.project_id
  name                  = "backstage-cloudsql-psc"
  region                = var.region
  target                = module.sql_instance.instances.primary.psc_service_attachment_link
  network               = module.backstage_vpc.self_link
  ip_address            = module.addresses.internal_addresses["backstage-psc-ip"].id
  load_balancing_scheme = ""
}
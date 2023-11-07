module "proxy_snat_sa" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v27.0.0"
  project_id = module.backstage_project.project_id
  name       = "backstage-gke-proxy-sa"
}

module "proxy_snat" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/compute-vm?ref=v27.0.0"
  project_id    = module.backstage_project.project_id
  zone          = "${var.region}-b"
  name          = "backstage-gke-proxy-vm"
  instance_type = "e2-micro"

  network_interfaces = [{
    network    = module.backstage_vpc.self_link
    subnetwork = module.backstage_vpc.subnet_self_links["${var.region}/backstage-gke-proxy"]
    nat        = false
  }]

  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-10"
      type  = "pd-balanced"
      size  = 10
    }
  }

  # metadata = {
  #   startup-script = "sysctl -w net.ipv4.ip_forward=1 && iptables -t nat -A POSTROUTING -j MASQUERADE"
  # }

  options = {
    spot               = true
    termination_action = "STOP"
  }
  # can_ip_forward = true
  service_account = {
    email = module.proxy_snat_sa.email
  }
}
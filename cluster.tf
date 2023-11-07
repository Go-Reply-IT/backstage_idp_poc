# -------------------------------------------------------------------------------
# GKE Cluster
# -------------------------------------------------------------------------------
module "gke_cluster" {
  source = "./modules/gke-cluster-standard27"
  # source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-standard?ref=v27.0.0"
  project_id = module.backstage_project.project_id
  name       = "backstage-cluster"
  location   = "${var.region}-b"

  max_pods_per_node = 16
  vpc_config = {
    network    = module.backstage_vpc.self_link
    subnetwork = module.backstage_vpc.subnet_self_links["${var.region}/backstage-gke"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
    min_master_version       = "1.24"
    issue_client_certificate = false
    release_channel          = upper("regular")
    master_authorized_ranges = {
      proxy = "10.0.0.32/29"
    }
    master_ipv4_cidr_block = "10.0.0.16/28"
  }

  enable_features = {
    workload_identity    = true
    pod_security_policy  = false
    dataplane_v2         = true
    binary_authorization = true
  }

  private_cluster_config = {
    master_global_access    = false
    enable_private_endpoint = true
  }

  enable_addons = {
    network_policy                 = false
    gce_persistent_disk_csi_driver = true
    http_load_balancing            = true
  }

  depends_on = [
    module.pga_dns,
  ]
}

# Service Account NodePool
module "gke_sa" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v27.0.0"
  project_id = module.backstage_project.project_id
  name       = "backstage-gke-sa"
}


# NodePool
module "gke_nodepool" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-nodepool?ref=v27.0.0"
  project_id   = module.backstage_project.project_id
  cluster_name = module.gke_cluster.name
  location     = module.gke_cluster.location
  name         = "backstage-nodepool"

  # Requirement 6.2.1.
  service_account = {
    create = false
    email  = module.gke_sa.email
  }
  node_count = {
    #TODO: portare a 6
    initial = 1
  }
  node_config = {
    #TODO After migration change to reference to module kms
    # boot_disk_kms_key = data.google_kms_crypto_key.gke_boot_crypto_key.id
    disk_size_gb = 20
    disk_type    = "pd-standard"
    machine_type = "e2-standard-2"
    preemptible  = true
    # Requirement 6.5.5
    shielded_instance_config = {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
    # Requirement 6.4.2
    metadata = {
      node_metadata = "GKE_METADATA_SERVER"
    }
  }

  nodepool_config = {
    management = {
      # Requirement 2.2.5 of PCI-DSS
      auto_repair = true
      # Requirement 6.5.3 and 2.2.5 of PCI-DSS
      auto_upgrade = true
    }
  }
}
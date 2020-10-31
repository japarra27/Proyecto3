#################################################################
#################### PROVIDER CONFIGURATION #####################
#################################################################

# define the provider info
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project = var.project_gcp
  region  = var.region_gcp
  zone    = var.zone_gcp
}

provider "google-beta" {
  project     = var.project_gcp
  credentials = file(var.credentials_file)
  region      = var.region_gcp
  zone        = var.zone_gcp
}

locals {cdn_domain = "designmatchgcp.com"}

#################################################################
#################### NETWORK CONFIGURATION ######################
#################################################################

# create VPC
resource "google_compute_network" "vpc" {
  name = "${var.app_name}-vpc"
  auto_create_subnetworks = "false"
  routing_mode = "GLOBAL"
}

# create public subnet
resource "google_compute_subnetwork" "public_subnet_1" {
  name = "${var.app_name}-public-subnet-1"
  ip_cidr_range = var.public_subnet_cidr_1
  network = google_compute_network.vpc.name
  region = var.region_gcp
}

# create a public ip for nat service
resource "google_compute_address" "nat-ip" {
  name = "${var.app_name}-nap-ip"
  project = var.project_gcp
  region  = var.region_gcp
}
# create a nat to allow private instances connect to internet
resource "google_compute_router" "nat-router" {
  name = "${var.app_name}-nat-router"
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat-gateway" {
  name = "${var.app_name}-nat-gateway"
  router = google_compute_router.nat-router.name
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = [ google_compute_address.nat-ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on = [ google_compute_address.nat-ip]
}


#################################################################
################### FIREWALL CONFIGURATION ######################
#################################################################

# allow http traffic
resource "google_compute_firewall" "allow-http" {
  name = "${var.app_name}-allow-http"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "22", "443", "2049", "111", "6379", "4200", "587"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["http-server"]
}

# allow https traffic
resource "google_compute_firewall" "allow-https" {
  name = "${var.app_name}-allow-https"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "22", "443", "2049", "111", "6379", "4200", "587"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["https-server"]
}

# allow ssh traffic
resource "google_compute_firewall" "allow-ssh" {
  name = "${var.app_name}-allow-ssh"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["ssh"]
}

# allow rdp traffic
resource "google_compute_firewall" "allow-rdp" {
  name = "${var.app_name}-allow-rdp"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["rdp"]
}

# allow internal
resource "google_compute_firewall" "allow-internal" {
  name    = "${var.app_name}-allow-internal"
  network = google_compute_network.vpc.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [var.public_subnet_cidr_1]
}

#################################################################
################ COMPUTE ENGINE CONFIGURATION ###################
#################################################################

########################### TEMPLATES ###########################

# Create backend template
resource "google_compute_instance_template" "template_mdd_backend" {
  
  name = "${var.app_name}-backend-template"
  description = "This template is used to create django backend"
  instance_description = "Web Server running Apache"
  can_ip_forward = false
  machine_type = "g1-small"
  tags = ["ssh", "rdp", "http-server", "https-server"]
  
  scheduling {
    automatic_restart = true
    on_host_maintenance = "MIGRATE"
  }
  
  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete = true
    boot = true
  }
  
  network_interface {
    network = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.public_subnet_1.name

      access_config {  
    }
  }
  
  lifecycle {
    create_before_destroy = false
  }

  service_account {
    scopes = ["userinfo-email", "cloud-platform", "taskqueue"]
  }
  
  metadata_startup_script = file("../create_backend.sh")
}

# Create frontend template
resource "google_compute_instance_template" "template_mdd_frontend" {
  
  name = "${var.app_name}-frontend-template"
  description = "This template is used to create Angular"
  instance_description = "Web Server running Angular"
  can_ip_forward = false
  machine_type = "g1-small"
  tags = ["ssh", "rdp", "http-server", "https-server"]

  scheduling {
    automatic_restart = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete = true
    boot = true
  }
  
  network_interface {
    network = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.public_subnet_1.name

      access_config {  
    }
  }
  
  lifecycle {
    create_before_destroy = false
  }

  service_account {
    scopes = ["userinfo-email", "cloud-platform", "taskqueue"]
  }

  metadata_startup_script = file("../create_frontend.sh")
}

# Create worker template
resource "google_compute_instance_template" "template_mdd_worker" {
  
  name = "${var.app_name}-worker-template"
  description = "This template is used to celery worker"
  instance_description = "Web Server running Celery"
  can_ip_forward = false
  machine_type = "g1-small"
  tags = ["ssh", "rdp", "http-server", "https-server"]
  
  scheduling {
    automatic_restart = true
    on_host_maintenance = "MIGRATE"
  }
  
  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete = true
    boot = true
  }
  
  network_interface {
    network = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.public_subnet_1.name

  access_config {  
    }
  }
  lifecycle {
    create_before_destroy = false
  }

  service_account {
    scopes = ["userinfo-email", "cloud-platform", "taskqueue"]
  }

  metadata_startup_script = file("../create_workers.sh")
}

################ FRONTEND ###################

# Compute address - static_ip frontend - mdd
resource "google_compute_address" "static_mdd_front" {
  name = "ipv4-address-static-ip-mddfront"
}

# create the compute engine instance frontend - mdd
resource "google_compute_instance" "apps_mdd_front" {
  count        = 1
  name         = "${var.app_name}-frontend-${count.index + 1}"
  machine_type = "g1-small"
  zone         = var.zone_gcp
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
    }
  }

  metadata_startup_script = file("../create_frontend.sh")

  network_interface {
    network     = google_compute_network.vpc.name
    subnetwork  = google_compute_subnetwork.public_subnet_1.name
    network_ip = var.private_ip_front

    access_config {
      nat_ip = google_compute_address.static_mdd_front.address
    }
  }

  service_account {
    scopes = ["userinfo-email", "cloud-platform", "taskqueue"]
  }

  deletion_protection = false

  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["ssh", "rdp", "http-server", "https-server"]
}

#########################################################
################# HTTP LOAD BALANCER ####################
#########################################################

 #Load balancer with managed instance group and autoscale

# Compute address - static_ip frontend - mdd
resource "google_compute_global_address" "static_mdd_loadbalancer" {
  name = "ipv4-address-static-ip-mddlb"
  #address = "107.178.244.5"
}

resource "google_compute_global_address" "static_mdd_loadbalancer_worker" {
  name = "ipv4-address-static-ip-mddlb-worker"
}

# used to forward traffic to the correct load balancer for HTTP load balancing 
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "${var.app_name}-${var.app_environment}-global-forwarding-rule"
  project    = var.project_gcp
  target     = google_compute_target_http_proxy.target_http_proxy.self_link
  port_range = 80
  ip_address = google_compute_global_address.static_mdd_loadbalancer.address
}

# used to forward traffic to the correct load balancer for HTTP load balancing 
resource "google_compute_global_forwarding_rule" "global_forwarding_rule_worker" {
  name       = "${var.app_name}-${var.app_environment}-global-forwarding-rule-worker"
  project    = var.project_gcp
  target     = google_compute_target_http_proxy.target_http_proxy_worker.self_link
  port_range = 80
  ip_address = google_compute_global_address.static_mdd_loadbalancer_worker.address
}

# used by one or more global forwarding rule to route incoming HTTP requests to a URL map
resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = "${var.app_name}-${var.app_environment}-proxy"
  project = var.project_gcp
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_target_http_proxy" "target_http_proxy_worker" {
  name    = "${var.app_name}-${var.app_environment}-proxy-worker"
  project = var.project_gcp
  url_map = google_compute_url_map.url_map_worker.self_link
}

# defines a group of virtual machines that will serve traffic for load balancing
resource "google_compute_backend_service" "backend_service" {
  name                    = "${var.app_name}-${var.app_environment}-backend-service"
  project                 = var.project_gcp
  port_name               = "http"
  protocol                = "HTTP"
  load_balancing_scheme   = "EXTERNAL"
  health_checks           = [google_compute_health_check.healthcheck.self_link]

  backend {
    group                 = google_compute_instance_group_manager.back_private_group.instance_group
    balancing_mode        = "RATE"
    max_rate_per_instance = 80
  }
}

# defines a group of virtual machines that will serve traffic for load balancing
resource "google_compute_backend_service" "worker_service" {
  name                    = "${var.app_name}-${var.app_environment}-worker-service"
  project                 = var.project_gcp
  port_name               = "http"
  protocol                = "HTTP"
  load_balancing_scheme   = "EXTERNAL"
  health_checks           = [google_compute_health_check.healthcheck_worker.self_link]

  backend {
    group                 = google_compute_instance_group_manager.back_private_group.instance_group
    balancing_mode        = "RATE"
    max_rate_per_instance = 80
  }
}

# creates a group of virtual machine instances - backend
resource "google_compute_instance_group_manager" "back_private_group" {
  name                 = "${var.app_name}-${var.app_environment}-vm-group-backend"
  project              = var.project_gcp
  base_instance_name   = "${var.app_name}-${var.app_environment}-backend"
  zone                 = var.zone_gcp
  version {
    instance_template  = google_compute_instance_template.template_mdd_backend.self_link
  }
  named_port {
    name = "http"
    port = 8080
  }
}

# creates a group of virtual machine instances - workers
resource "google_compute_instance_group_manager" "worker_private_group" {
  name                 = "${var.app_name}-${var.app_environment}-vm-group-worker"
  project              = var.project_gcp
  base_instance_name   = "${var.app_name}-${var.app_environment}-worker"
  zone                 = var.zone_gcp
  version {
    instance_template  = google_compute_instance_template.template_mdd_worker.self_link
  }
}

# determine whether instances are responsive and able to do work
resource "google_compute_health_check" "healthcheck" {
  name               = "${var.app_name}-${var.app_environment}-healthcheck"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port = 8080
  }
}

# determine whether instances are responsive and able to do work
resource "google_compute_health_check" "healthcheck_worker" {
  name               = "${var.app_name}-${var.app_environment}-healthcheckworker"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port = 8080
  }
}

# used to route requests to a backend service based on rules that you define for the host and path of an incoming URL
resource "google_compute_url_map" "url_map" {
  name            = "${var.app_name}-${var.app_environment}-load-balancer"
  project         = var.project_gcp
  default_service = google_compute_backend_service.backend_service.self_link
}

# used to route requests to a worker service based on rules that you define for the host and path of an incoming URL
resource "google_compute_url_map" "url_map_worker" {
  name            = "${var.app_name}-${var.app_environment}-load-balancer-worker"
  project         = var.project_gcp
  default_service = google_compute_backend_service.worker_service.self_link
}

# automatically scale virtual machine instances in managed instance groups according to an autoscaling policy
resource "google_compute_autoscaler" "autoscaler-back" {
  name    = "${var.app_name}-autoscaler-back"
  project = var.project_gcp
  zone    = var.zone_gcp
  target  = google_compute_instance_group_manager.back_private_group.self_link

  autoscaling_policy {
    max_replicas    = var.lb_max_replicas
    min_replicas    = var.lb_min_replicas
    cooldown_period = var.lb_cooldown_period

    cpu_utilization {
      target = 0.7
    }
  }
}

resource "google_compute_autoscaler" "autoscaler_worker" {
  name    = "${var.app_name}-autoscaler-worker"
  project = var.project_gcp
  zone    = var.zone_gcp
  target  = google_compute_instance_group_manager.worker_private_group.self_link

  autoscaling_policy {
    max_replicas    = var.lb_max_replicas
    min_replicas    = var.lb_min_replicas
    cooldown_period = var.lb_cooldown_period

    cpu_utilization {
      target = 0.7
    }
  }
}


#######################################################################
######################## MEMORY STORE - REDIS #########################
#######################################################################

resource "random_id" "redis_name_suffix" {
  byte_length = 4
  }

resource "google_compute_global_address" "service_range" {
  name          = "${var.app_name}-${random_id.redis_name_suffix.hex}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.service_range.name]
}

resource "google_redis_instance" "cache" {
  name           = "memorystore-${var.app_name}-${random_id.redis_name_suffix.hex}"
  tier           = "STANDARD_HA"
  memory_size_gb = 1

  location_id             = var.zone_gcp

  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version     = "REDIS_4_0"
  display_name      = "Terraform Test Instance"

  depends_on = [google_service_networking_connection.private_service_connection]
}

#######################################################################
########################## BUCKETS AND CDN ############################
#######################################################################

# ------------------------------------------------------------------------------
# CREATE A STORAGE BUCKET
# ------------------------------------------------------------------------------
 
resource "google_storage_bucket" "cdn_bucket" {
  name          = "${var.app_name}-cdn-bucket"
  storage_class = "MULTI_REGIONAL"
  location      = "EU" # You might pass this as a variable
  project       = var.project_gcp
}
 
# ------------------------------------------------------------------------------
# CREATE A BACKEND CDN BUCKET
# ------------------------------------------------------------------------------
 
resource "google_compute_backend_bucket" "cdn_backend_bucket" {
  name        = "${var.app_name}-cdn-backend-bucket"
  description = "Backend bucket for serving static content through CDN"
  bucket_name = google_storage_bucket.cdn_bucket.name
  enable_cdn  = true
  project     = var.project_gcp
}

# ------------------------------------------------------------------------------
# CREATE A URL MAP
# ------------------------------------------------------------------------------
 
resource "google_compute_url_map" "cdn_url_map" {
  name            = "cdn-url-map"
  description     = "CDN URL map to cdn_backend_bucket"
  default_service = google_compute_backend_bucket.cdn_backend_bucket.self_link
  project         = var.project_gcp
}

# ------------------------------------------------------------------------------
# CREATE A GOOGLE COMPUTE MANAGED CERTIFICATE
# ------------------------------------------------------------------------------
resource "google_compute_managed_ssl_certificate" "cdn_certificate" {
  provider = google-beta
  project  = var.project_gcp
 
  name = "cdn-managed-certificate"
 
  managed {
    domains = [local.cdn_domain]
  }
}
 
# ------------------------------------------------------------------------------
# CREATE HTTPS PROXY
# ------------------------------------------------------------------------------
 
resource "google_compute_target_https_proxy" "cdn_https_proxy" {
  name             = "cdn-https-proxy"
  url_map          = google_compute_url_map.cdn_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.cdn_certificate.self_link]
  project          = var.project_gcp
}

# ------------------------------------------------------------------------------
# CREATE A GLOBAL PUBLIC IP ADDRESS
# ------------------------------------------------------------------------------
 
resource "google_compute_global_address" "cdn_public_address" {
  name         = "cdn-public-address"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
  project      = var.project_gcp
}
 
# ------------------------------------------------------------------------------
# CREATE A GLOBAL FORWARDING RULE
# ------------------------------------------------------------------------------
 
resource "google_compute_global_forwarding_rule" "cdn_global_forwarding_rule" {
  name       = "cdn-global-forwarding-https-rule"
  target     = google_compute_target_https_proxy.cdn_https_proxy.self_link
  ip_address = google_compute_global_address.cdn_public_address.address
  port_range = "443"
  project    = var.project_gcp
}

# ------------------------------------------------------------------------------
# MAKE THE BUCKET PUBLIC
# ------------------------------------------------------------------------------
 
resource "google_storage_bucket_iam_member" "all_users_viewers" {
  bucket = google_storage_bucket.cdn_bucket.name
  role   = "roles/storage.legacyObjectReader"
  member = "allUsers"
}
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

#################################################################
#################### NETWORK CONFIGURATION ######################
#################################################################

# create VPC
resource "google_compute_network" "vpc" {
  name = "${var.app_name}-vpc"
  auto_create_subnetworks = "false"
  routing_mode = "GLOBAL"
}

# # create private subnet
# resource "google_compute_subnetwork" "private_subnet_1" {
#  provider = google-beta
#  purpose = "PRIVATE"
#  name = "${var.app_name}-private-subnet-1"
#  ip_cidr_range = var.private_subnet_cidr_1
#  network = google_compute_network.vpc.name
#  region = var.region_gcp
# }

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
  name = "${var.app_name}-fw-allow-http"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "4200"]
  }
  target_tags = ["http-server"]
}

# allow https traffic
resource "google_compute_firewall" "allow-https" {
  name = "${var.app_name}-fw-allow-https"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["443", "4200"]
  }
  target_tags = ["https-server"]
}

# allow ssh traffic
resource "google_compute_firewall" "allow-ssh" {
  name = "${var.app_name}-fw-allow-ssh"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["ssh"]
}

# allow rdp traffic
resource "google_compute_firewall" "allow-rdp" {
  name = "${var.app_name}-fw-allow-rdp"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  target_tags = ["rdp"]
}

# allow internal
resource "google_compute_firewall" "allow-internal" {
  name    = "${var.app_name}-fw-allow-internal"
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
  source_ranges = [
    var.public_subnet_cidr_1
  ]
}

#################################################################
################ COMPUTE ENGINE CONFIGURATION ###################
#################################################################

############################ TEMPLAES ###########################

# Create backend template
resource "google_compute_instance_template" "template_mdc_backend" {
  name = "${var.app_name}-backend-template"
  description = "This template is used to create django backend"
  instance_description = "Web Server running Apache"
  can_ip_forward = false
  machine_type = "g1-small"
  tags = ["ssh","http"]
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
  }
  
  lifecycle {
    create_before_destroy = false
  }
  metadata_startup_script = file("../create_backend.sh")
}

# Create frontend template
resource "google_compute_instance_template" "template_mdc_frontend" {
  name = "${var.app_name}-frontend-template"
  description = "This template is used to create Angular"
  instance_description = "Web Server running Angular"
  can_ip_forward = false
  machine_type = "g1-small"
  tags = ["ssh","http"]
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
  }
  
  lifecycle {
    create_before_destroy = false
  }
  metadata_startup_script = file("../create_frontend.sh")
}

# Create worker template
resource "google_compute_instance_template" "template_mdc_worker" {
  name = "${var.app_name}-worker-template"
  description = "This template is used to celery worker"
  instance_description = "Web Server running Celery"
  can_ip_forward = false
  machine_type = "g1-small"
  tags = ["ssh","http"]
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
  }
  
  lifecycle {
    create_before_destroy = false
  }
  metadata_startup_script = file("../create_workers.sh")
}

# Create nfs template
resource "google_compute_instance_template" "template_mdc_nfs" {
  name = "${var.app_name}-nfs-template"
  description = "This template is used to create NFS"
  instance_description = "Web Server running NFS"
  can_ip_forward = false
  machine_type = "g1-small"
  tags = ["ssh","http"]
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
  }
  
  lifecycle {
    create_before_destroy = false
  }
  metadata_startup_script = file("../create_fileserver.sh")
}

################ BACKEND ###################

# # create the compute engine instance backend - MDC
# resource "google_compute_instance" "apps_mdc_back" {
#   count        = 1
#   name         = "${var.app_name}-backend-${count.index + 1}"
#   machine_type = "n2-standard-2"
#   zone         = var.zone_gcp
#   allow_stopping_for_update = true

#   boot_disk {
#     initialize_params {
#       image = "ubuntu-1804-bionic-v20200908"
#     }
#   }

#   metadata_startup_script = file("../create_backend.sh")

#   network_interface {
#     network     = google_compute_network.vpc.name
#     subnetwork  = google_compute_subnetwork.public_subnet_1.name

#     access_config {
#     }
#   }

#   // Apply the firewall rule to allow external IPs to access this instance
#   tags = ["http-server", "https-server", "ssh", "rdp"]
# }

################ WORKERS ###################

# create the compute engine instance worker - MDC
# resource "google_compute_instance" "apps_mdc_worker" {
#   count        = 1
#   name         = "${var.app_name}-worker-${count.index + 1}"
#   machine_type = "n2-standard-2"
#   zone         = var.zone_gcp
#   allow_stopping_for_update = true

#   boot_disk {
#     initialize_params {
#       image = "ubuntu-1804-bionic-v20200908"
#     }
#   }

#   metadata_startup_script = file("../create_workers.sh")

#   network_interface {
#     network     = google_compute_network.vpc.name
#     subnetwork  = google_compute_subnetwork.public_subnet_1.name

#     access_config {
#     }
#   }
# }

################ FRONTEND ###################

# Compute address - static_ip frontend - MDC
resource "google_compute_address" "static_mdc_front" {
  name = "ipv4-address-static-ip-mdcfront"
}

# create the compute engine instance frontend - MDC
resource "google_compute_instance" "apps_mdc_front" {
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

    access_config {
      nat_ip = google_compute_address.static_mdc_front.address
    }
  }

  deletion_protection = false

  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["http-server", "https-server", "ssh", "rdp"]
}

################ FILESERVER ###################

# Compute address - static_ip fileserver - MDC
resource "google_compute_address" "static_mdc_nfs" {
  name      = "ipv4-address-static-ip-mdcnfs"
}

# create the compute engine instance fileserver - MDC
resource "google_compute_instance" "apps_mdc_nfs" {
  count        = 1
  name         = "${var.app_name}-nfs-${count.index + 1}"
  machine_type = "g1-small"
  zone         = var.zone_gcp
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
    }
  }

  metadata_startup_script = file("../create_fileserver.sh")

  network_interface {
    network     = google_compute_network.vpc.name
    subnetwork  = google_compute_subnetwork.public_subnet_1.name
    network_ip = var.private_ip_nfs

    access_config {
    }
  }
  
  deletion_protection = false
  
  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["http-server", "https-server", "ssh", "rdp"]
}

#################################################################
################### DATABASE CONFIGURATION ######################
#################################################################

# database creation
resource "google_sql_database_instance" "postgres_mdc" {
  name             = "postgres-instance-designmatch"
  database_version = "POSTGRES_12"
  deletion_protection = false 

  settings {
    tier = "db-f1-micro"
    disk_size = "10"
    disk_type = "PD_SSD"

    location_preference {
      zone = var.zone_gcp
      }
   
    maintenance_window {
      day  = "7"  # sunday
      hour = "3" # 3am
      }
   
    backup_configuration {
      enabled = true
      start_time = "00:00"
      }
      
    ip_configuration {
      ipv4_enabled = "true"
      authorized_networks {
        value = "0.0.0.0/0"
        }
      } 
  }
}

# database name
resource "google_sql_database" "database_mdc" {
  name     = "designmatch-mdc"
  instance = google_sql_database_instance.postgres_mdc.name
}

# database username
resource "google_sql_user" "users_mdc" {
  name     = "designmatchadmin"
  instance = google_sql_database_instance.postgres_mdc.name
  password = var.password
}


################# HTTP LOAD BALANCER ####################

 #Load balancer with managed instance group and autoscale | lb-unmanaged.tf

# used to forward traffic to the correct load balancer for HTTP load balancing 
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "${var.app_name}-${var.app_environment}-global-forwarding-rule"
  project    = var.project_gcp
  target     = google_compute_target_http_proxy.target_http_proxy.self_link
  port_range = "80"
}

# used by one or more global forwarding rule to route incoming HTTP requests to a URL map
resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = "${var.app_name}-${var.app_environment}-proxy"
  project = var.project_gcp
  url_map = google_compute_url_map.url_map.self_link
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
    max_rate_per_instance = 100
  }
}

# creates a group of virtual machine instances - backend
resource "google_compute_instance_group_manager" "back_private_group" {
  name                 = "${var.app_name}-${var.app_environment}-vm-group-backend"
  project              = var.project_gcp
  base_instance_name   = "${var.app_name}-${var.app_environment}-backend"
  zone                 = var.zone_gcp
  version {
    instance_template  = google_compute_instance_template.template_mdc_backend.self_link
  }
  named_port {
    name = "http"
    port = 80
  }
}

# creates a group of virtual machine instances - workers
resource "google_compute_instance_group_manager" "worker_private_group" {
  name                 = "${var.app_name}-${var.app_environment}-vm-group-worker"
  project              = var.project_gcp
  base_instance_name   = "${var.app_name}-${var.app_environment}-worker"
  zone                 = var.zone_gcp
  version {
    instance_template  = google_compute_instance_template.template_mdc_worker.self_link
  }
  named_port {
    name = "http"
    port = 80
  }
}

# determine whether instances are responsive and able to do work
resource "google_compute_health_check" "healthcheck" {
  name               = "${var.app_name}-${var.app_environment}-healthcheck"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port = 80
  }
}

# used to route requests to a backend service based on rules that you define for the host and path of an incoming URL
resource "google_compute_url_map" "url_map" {
  name            = "${var.app_name}-${var.app_environment}-load-balancer"
  project         = var.project_gcp
  default_service = google_compute_backend_service.backend_service.self_link
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
      target = 0.8
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
      target = 0.8
    }
  }
}

# show external ip address of load balancer
output "load-balancer-ip-address" {
  value = google_compute_global_forwarding_rule.global_forwarding_rule.ip_address
}
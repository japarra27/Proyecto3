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

#################################################################
################### FIREWALL CONFIGURATION ######################
#################################################################

# allow http traffic
resource "google_compute_firewall" "allow-http" {
  name = "${var.app_name}-fw-allow-http"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["http-server"]
}

# allow https traffic
resource "google_compute_firewall" "allow-https" {
  name = "${var.app_name}-fw-allow-https"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["443"]
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
    "${var.public_subnet_cidr_1}"
  ]
}

#################################################################
################ COMPUTE ENGINE CONFIGURATION ###################
#################################################################

################ BACKEND ###################

# create the compute engine instance backend - MDC
resource "google_compute_instance" "apps_mdc_back" {
  count        = 1
  name         = "${var.app_name}-backend-${count.index + 1}"
  machine_type = "n2-standard-2"
  zone         = var.zone_gcp
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20200908"
    }
  }

  metadata_startup_script = file("../create_backend.sh")

  network_interface {
    network     = google_compute_network.vpc.name
    subnetwork  = google_compute_subnetwork.public_subnet_1.name

    access_config {
    }
  }

  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["http-server", "https-server", "ssh", "rdp"]
}

################ WORKERS ###################

# create the compute engine instance backend - MDC
resource "google_compute_instance" "apps_mdc_worker" {
  count        = 1
  name         = "${var.app_name}-worker-${count.index + 1}"
  machine_type = "n2-standard-2"
  zone         = var.zone_gcp
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20200908"
    }
  }

  metadata_startup_script = file("../create_workers.sh")

  network_interface {
    network     = google_compute_network.vpc.name
    subnetwork  = google_compute_subnetwork.public_subnet_1.name

    access_config {
    }
  }
}

################ FRONTEND ###################

# Compute address - static_ip frontend - MDC
resource "google_compute_address" "static_mdc_front" {
  name = "ipv4-address-static-ip-mdcfront"
}

# create the compute engine instance frontend - MDC
resource "google_compute_instance" "apps_mdc_front" {
  count        = 1
  name         = "${var.app_name}-frontend-${count.index + 1}"
  machine_type = "e2-standard-2"
  zone         = var.zone_gcp
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20200908"
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

  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["http-server", "https-server", "ssh", "rdp"]
}

################ FILESERVER ###################

# Compute address - static_ip fileserver - MDC
resource "google_compute_address" "static_mdc_nfs" {
  name      = "ipv4-address-static-ip-mdcnfs"
  address   = var.private_ip_nfs
}

# create the compute engine instance fileserver - MDC
resource "google_compute_instance" "apps_mdc_nfs" {
  count        = 1
  name         = "${var.app_name}-nfs-${count.index + 1}"
  machine_type = "n2-standard-2"
  zone         = var.zone_gcp
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20200908"
    }
  }

  metadata_startup_script = file("../create_fileserver.sh")

  network_interface {
    network     = google_compute_network.vpc.name
    subnetwork  = google_compute_subnetwork.public_subnet_1.name

    access_config {
      nat_ip = google_compute_address.static_mdc_nfs.address
    }
  }
  
  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["http-server", "https-server", "ssh", "rdp"]
}

#################################################################
################### DATABASE CONFIGURATION ######################
#################################################################

# database creation
resource "google_sql_database_instance" "postgres_mdc" {
  name             = "postgres-instance-designmatch-mdc"
  database_version = "POSTGRES_12"
  
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
      private_network = var.private_ip_db
      authorized_networks {
        value = var.public_subnet_cidr_1
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

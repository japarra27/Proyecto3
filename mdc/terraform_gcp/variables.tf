#################################################################
#################### GENERAL CONFIGURATION ######################
#################################################################

# gcp credentials file
variable "credentials_file" {
  description = "Name of the credentials file"
  type        = string
}

# gcp project name
variable "project_gcp" {
  description = "Name of the GCP project"
  type        = string
}

# gcp region name
variable "region_gcp" {
  description = "Name of the GCP region"
  type        = string
  default     = "us-west1"
}

#gcp zone name
variable "zone_gcp" {
  description = "Name of the GCP zone"
  type        = string
  default     = "us-west1-b"
}

# name of the application project
variable "app_name" {
    type = string
    description = "name of the app name"
}

# name of the environment project
variable "app_environment" {
    type = string
    description = "name of the app name"
}

#################################################################
################### SPECIFIC CONFIGURATION ######################
#################################################################

# gcp Cloud-SQL database password
variable "password" {
  description = "Postgresql password database"
  type        = string
}

# # gcp Cloud-SQL private ip
# variable "private_ip_db" {
#   description = "private ip adress from VPC to the database"
#   type        = string
# }

# gcp compute engine - number of instances
variable "node_count" {
 type    = number
 default = 1
}

# gcp subnet
# define Public subnet
variable "public_subnet_cidr_1" {
  type = string
  description = "Public subnet CIDR 1"
}

# # define Private subnet
# variable "private_subnet_cidr_1" {
#   type = string
#   description = "Private subnet CIDR 1"
# }

# # specific cidr postgres instacne
# variable "db_instance_access_cidr" {
#   description = "The IPv4 CIDR to provide access the database instance"
#   type        = string
# }

# gcp nfs private ip
variable "private_ip_nfs" {
  description = "private ip adress from VPC to the nfs"
  type        = string
}

# gcp front private ip
variable "private_ip_front" {
  description = "private ip adress from VPC to the front"
  type        = string
}

# maximum number of VMs for load balancer autoscale
variable "lb_max_replicas" {
  type        = string
  description = "Maximum number of VMs for autoscale"
  default     = "4"
}

# minimum number of VMs for load balancer autoscale
variable "lb_min_replicas" {
  type        = string
  description = "Minimum number of VMs for autoscale"
  default     = "1"
}

# number of seconds that the autoscaler should wait before it starts collecting information
variable "lb_cooldown_period" {
  type        = string
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a new instance"
  default     = "60"
}
variable "projectID" {
  type        = string
  description = "project ID"
}

variable "region" {
  type        = string
  description = "region for the vpc"
}

variable "zone" {
  type        = string
  description = "zone for the vpc"
}

variable "vpc_name" {
  type        = string
  description = "VPC name"
  default     = "vpc"
}

variable "routing_mode" {
  type        = string
  description = "routing mode for VPC"
}

variable "subnet_1_name" {
  type        = string
  description = "webapp subnet"
}

variable "subnet_2_name" {
  type        = string
  description = "db subnet"
}

variable "subnet1_ip_range" {
  type        = string
  description = "webapp subnet ip cidr range"
}

variable "subnet2_ip_range" {
  type        = string
  description = "db subnet ip cidr range"
}

variable "next_hop_gateway" {
  type        = string
  description = "next hop gateway"
}
variable "route_1_name" {
  type        = string
  description = "webapp route name"
}

variable "route1_destination_range" {
  type        = string
  description = "destination range of webapp"

}

variable "total_count" {
  type        = number
  description = "number of vpcs and resources to be created"

}

variable "firewall_Rule_1" {
  type        = string
  description = "Name of first firewall rule of subnet 1"
}

variable "firewall_Rule_2" {
  type        = string
  description = "Name of second firewall rule of subnet 2"

}

variable "firewall_1_port" {
  type        = string
  description = "Port allowed for first firewall rule"
}

variable "firewall_2_port" {
  type        = string
  description = "Port to be protected for second firewall rule"
}

variable "firewall_1_protocol" {
  type        = string
  description = "Protocol allowed for first firewall rule"
}

variable "firewall_2_protocol" {
  type        = string
  description = "Protocol allowed for second firewall rule"
}

variable "firewall_source_ranges" {
  type        = string
  description = "Source range for firewalls"
}

variable "google_compute_instance_name" {
  type        = string
  description = "Name for the google compute instance"
}

variable "google_compute_instance_machine_type" {
  type        = string
  description = "Machine type for Google instance"
}

variable "machine_image_name" {
  type        = string
  description = "Name of the image to be used by google compute instance"
}

variable "disk_size" {
  type        = string
  description = "size value of the disk"
}

variable "disk_type" {
  type        = string
  description = "type of the disk"
}

variable "network_interface_network_tier" {
  type        = string
  description = "Tier to be configured for network of network interface"
}
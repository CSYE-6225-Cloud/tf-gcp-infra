provider "google" {
  project = var.projectID
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "virtual_private_cloud" {
  name                            = var.vpc_name
  description                     = "Creating a vpc"
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "subnet_1" {
  name          = var.subnet_1_name
  description   = "first subnet webapp"
  region        = var.region
  network       = google_compute_network.virtual_private_cloud.self_link
  ip_cidr_range = var.subnet1_ip_range
}

resource "google_compute_subnetwork" "subnet_2" {
  name          = var.subnet_2_name
  description   = "second subnet db"
  region        = var.region
  network       = google_compute_network.virtual_private_cloud.self_link
  ip_cidr_range = var.subnet2_ip_range
}

resource "google_compute_route" "route_resource" {
  name             = var.route_1_name
  network          = google_compute_network.virtual_private_cloud.self_link
  dest_range       = var.route1_destination_range
  next_hop_gateway = "default-internet-gateway"
}
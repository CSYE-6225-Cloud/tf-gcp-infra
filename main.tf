provider "google" {
  project = var.projectID
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "virtual_private_cloud" {
  count                           = var.total_count
  name                            = "${var.vpc_name}-${count.index}"
  description                     = "Creating a vpc"
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "subnet_1" {
  count         = var.total_count
  name          = "${var.subnet_1_name}"
  description   = "first subnet webapp"
  region        = var.region
  network       = google_compute_network.virtual_private_cloud[count.index].id
  ip_cidr_range = var.subnet1_ip_range
}

resource "google_compute_subnetwork" "subnet_2" {
  count         = var.total_count
  name          = "${var.subnet_2_name}"
  description   = "second subnet db"
  region        = var.region
  network       = google_compute_network.virtual_private_cloud[count.index].id
  ip_cidr_range = var.subnet2_ip_range
}

resource "google_compute_route" "route_resource" {
  count            = var.total_count
  name             = "${var.route_1_name}-${count.index}"
  network          = google_compute_network.virtual_private_cloud[count.index].id
  dest_range       = var.route1_destination_range
  next_hop_gateway = "default-internet-gateway"
}

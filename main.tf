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
  name          = var.subnet_1_name
  description   = "first subnet webapp"
  region        = var.region
  network       = google_compute_network.virtual_private_cloud[count.index].id
  ip_cidr_range = var.subnet1_ip_range
}

resource "google_compute_subnetwork" "subnet_2" {
  count         = var.total_count
  name          = var.subnet_2_name
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
  next_hop_gateway = var.next_hop_gateway
}

resource "google_compute_firewall" "allow_traffic_to_port_rule" {
  name    = var.firewall_Rule_1
  network = google_compute_network.virtual_private_cloud[0].name
  allow {
    protocol = var.firewall_1_protocol
    ports    = [var.firewall_1_port]
  }
  source_ranges = [var.firewall_source_ranges]
}

resource "google_compute_firewall" "deny_traffic_to_ssh_rule" {
  name    = var.firewall_Rule_2
  network = google_compute_network.virtual_private_cloud[0].name
  deny {
    protocol = var.firewall_2_protocol
    ports    = [var.firewall_2_port]
  }
  source_ranges = [var.firewall_source_ranges]
}

resource "google_compute_instance" "web_instance" {
  name         = var.google_compute_instance_name
  machine_type = var.google_compute_instance_machine_type

  boot_disk {
    initialize_params {
      image = var.machine_image_name
      size  = var.disk_size
      type  = var.disk_type
    }
  }
  network_interface {
    network    = google_compute_network.virtual_private_cloud[0].id
    subnetwork = google_compute_subnetwork.subnet_1[0].id
    access_config {
      network_tier = var.network_interface_network_tier
    }
  }

  depends_on = [
    google_compute_network.virtual_private_cloud,
    google_compute_firewall.allow_traffic_to_port_rule,
    google_compute_firewall.deny_traffic_to_ssh_rule
  ]

}

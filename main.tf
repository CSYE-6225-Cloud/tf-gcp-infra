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
  name                     = var.subnet_1_name
  description              = "first subnet webapp"
  region                   = var.region
  network                  = google_compute_network.virtual_private_cloud.id
  ip_cidr_range            = var.subnet1_ip_range
  # private_ip_google_access = true
  depends_on = [ google_sql_database_instance.postgres_db_instance ]
}

# resource "google_compute_subnetwork" "subnet_2" {
#   name          = var.subnet_2_name
#   description   = "second subnet db"
#   region        = var.region
#   network       = google_compute_network.virtual_private_cloud.id
#   ip_cidr_range = var.subnet2_ip_range
#   # private_ip_google_access = true
# }

resource "google_compute_global_address" "global-private-access-ip" {
  name          = "global-private-access-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.virtual_private_cloud.id
}
resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.virtual_private_cloud.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.global-private-access-ip.name]
}

# resource "google_compute_global_address" "default" {
#   name = "global-private-access-ip"
#   address_type = "INTERNAL"
#   purpose      = "PRIVATE_SERVICE_CONNECT"
#   network      = google_compute_network.virtual_private_cloud.id
#   address      = "10.3.0.5"

# } 
# resource "google_compute_global_forwarding_rule" "default" {
#   name                  = "globalrule"
#   target                = "all-apis"
#   network               = google_compute_network.virtual_private_cloud.id
#   ip_address            = google_compute_global_address.default.id
#   load_balancing_scheme = ""
# }
resource "google_compute_route" "route_resource" {
  name             = var.route_1_name
  network          = google_compute_network.virtual_private_cloud.id
  dest_range       = var.route1_destination_range
  next_hop_gateway = var.next_hop_gateway
}


resource "google_compute_firewall" "allow_traffic_to_port_rule" {
  name    = var.firewall_Rule_1
  network = google_compute_network.virtual_private_cloud.name
  allow {
    protocol = var.firewall_1_protocol
    ports    = [var.firewall_1_port]
  }
  source_ranges = [var.firewall_source_ranges]
}

resource "google_compute_firewall" "deny_traffic_to_ssh_rule" {
  name    = var.firewall_Rule_2
  network = google_compute_network.virtual_private_cloud.name
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
    network    = google_compute_network.virtual_private_cloud.id
    subnetwork = google_compute_subnetwork.subnet_1.id
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


resource "google_sql_database_instance" "postgres_db_instance" {
  name = "postgres-db-instance"
  region = var.region
  database_version = "POSTGRES_15"
  deletion_protection = false
  
  depends_on = [ google_service_networking_connection.default ]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.virtual_private_cloud.id
      enable_private_path_for_google_cloud_services = true
    }
    availability_type = "REGIONAL"
    disk_type = "pd-ssd"
    disk_size = 100
  }
}

resource "google_sql_database" "postgres_db" {
  name = "webapp"
  instance = google_sql_database_instance.postgres_db_instance.name
  # deletion_policy = "ABANDON"
  depends_on = [ google_sql_database_instance.postgres_db_instance ]
}

resource "random_password" "user_password" {
  length = 16
  special = false
}
resource "google_sql_user" "db_user" {
  name = "webapp"
  instance = google_sql_database_instance.postgres_db_instance.name
  password = random_password.user_password.result
}

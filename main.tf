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
  network       = google_compute_network.virtual_private_cloud.id
  ip_cidr_range = var.subnet1_ip_range
  depends_on    = [google_sql_database_instance.postgres_db_instance]
}

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


resource "google_compute_firewall" "allow_traffic_to_dbinstance_rule" {
  name               = var.firewall_Rule_3
  network            = google_compute_network.virtual_private_cloud.name
  direction          = "EGRESS"
  destination_ranges = [google_sql_database_instance.postgres_db_instance.private_ip_address]
  allow {
    protocol = var.firewall_3_protocol
    ports    = [var.firewall_3_port]
  }
  priority    = 1001
  target_tags = ["web-instance"]
}

resource "google_compute_firewall" "deny_traffic_to_dbinstance_rule" {
  name               = var.firewall_Rule_4
  network            = google_compute_network.virtual_private_cloud.name
  direction          = "EGRESS"
  destination_ranges = [google_sql_database_instance.postgres_db_instance.private_ip_address]

  deny {
    protocol = var.firewall_4_protocol
    ports    = [var.firewall_4_port]
  }
  priority = 1002

}

resource "google_compute_global_address" "global-private-access-ip" {
  name          = var.google_compute_global_address_name
  purpose       = var.google_compute_global_address_purpose
  address_type  = var.google_compute_global_address_type
  prefix_length = var.google_compute_global_address_prefix_length
  network       = google_compute_network.virtual_private_cloud.id
}
resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.virtual_private_cloud.id
  service                 = var.google_service_networking_connection_service
  reserved_peering_ranges = [google_compute_global_address.global-private-access-ip.name]
  deletion_policy         = var.deletion_policy
}



resource "google_compute_instance" "web_instance" {
  name         = var.google_compute_instance_name
  machine_type = var.google_compute_instance_machine_type


  metadata_startup_script = <<-EOT
#!/bin/bash

cd /home/Cloud/webapp/ || exit

env_values=$(cat <<EOF
PORT=${var.port}
DB_NAME=${var.db_name}
DB_USER=${var.db_user}
DB_PASSWORD=${random_password.user_password.result}
HOST=${google_sql_database_instance.postgres_db_instance.private_ip_address}
DIALECT=${var.dialect}
EOF
)
echo "$env_values" | sudo tee .env >/dev/null
sudo chown csye6225:csye6225 .env 
echo ".env file created"

EOT
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
  tags = ["web-instance"]
}


resource "google_sql_database_instance" "postgres_db_instance" {
  name                = var.database_instance_name
  region              = var.region
  database_version    = var.database_version
  deletion_protection = false

  depends_on = [google_service_networking_connection.default]

  settings {
    tier = var.database_instance_tier
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.virtual_private_cloud.id
      enable_private_path_for_google_cloud_services = true
    }
    availability_type = var.database_instance_availability_type
    disk_type         = var.database_instance_disk_type
    disk_size         = var.disk_size
  }
}

resource "google_sql_database" "postgres_db" {
  name            = var.database_name
  instance        = google_sql_database_instance.postgres_db_instance.name
  deletion_policy = var.deletion_policy
  depends_on      = [google_sql_database_instance.postgres_db_instance]
}

resource "google_sql_user" "db_user" {
  name            = var.database_user
  instance        = google_sql_database_instance.postgres_db_instance.name
  deletion_policy = var.deletion_policy
  password        = random_password.user_password.result
  depends_on      = [google_sql_database.postgres_db]
}
resource "random_password" "user_password" {
  length  = 16
  special = false
}

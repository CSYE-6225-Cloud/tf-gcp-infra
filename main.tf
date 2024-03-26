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
  allow {
    protocol = var.firewall_2_protocol
    ports    = [var.firewall_2_port]
  }
  source_ranges = [var.firewall_source_ranges]
}


# resource "google_compute_firewall" "allow_traffic_to_dbinstance_rule" {
#   name               = var.firewall_Rule_3
#   network            = google_compute_network.virtual_private_cloud.name
#   direction          = "EGRESS"
#   destination_ranges = [google_sql_database_instance.postgres_db_instance.private_ip_address]
#   allow {
#     protocol = var.firewall_3_protocol
#     ports    = [var.firewall_3_port]
#   }
#   priority    = 1001
#   target_tags = ["web-instance"]
# }

# resource "google_compute_firewall" "deny_traffic_to_dbinstance_rule" {
#   name               = var.firewall_Rule_4
#   network            = google_compute_network.virtual_private_cloud.name
#   direction          = "EGRESS"
#   destination_ranges = [google_sql_database_instance.postgres_db_instance.private_ip_address]

#   deny {
#     protocol = var.firewall_4_protocol
#     ports    = [var.firewall_4_port]
#   }
#   priority = 1002

# }

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
NODE_ENV=PROD
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

  allow_stopping_for_update = true

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.service_account.email
    scopes = ["logging-write", "monitoring-write", "pubsub"]
  }

  depends_on = [
    google_compute_network.virtual_private_cloud,
    google_compute_firewall.allow_traffic_to_port_rule,
    google_compute_firewall.deny_traffic_to_ssh_rule,
    google_service_account.service_account
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

resource "google_dns_record_set" "a" {
  name         = var.google_dns_name
  managed_zone = var.google_dns_zone
  type         = var.google_dns_record_set_type
  ttl          = var.google_dns_record_set_ttl

  rrdatas    = [google_compute_instance.web_instance.network_interface[0].access_config[0].nat_ip]
  depends_on = [google_compute_instance.web_instance]
}


resource "google_service_account" "service_account" {
  account_id                   = var.google_service_account_id
  display_name                 = var.google_service_account_name
  create_ignore_already_exists = true
}

resource "google_project_iam_binding" "binding_logging_admin" {
  project = var.projectID
  role    = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
  depends_on = [google_service_account.service_account]
}

resource "google_project_iam_binding" "binding_monitoring_metric_writer" {
  project = var.projectID
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
  depends_on = [google_service_account.service_account]
}

resource "google_pubsub_topic" "publish_topic" {
  name                       = "verify_email"
  message_retention_duration = "604800s"
}

resource "google_pubsub_topic_iam_binding" "topic_binding" {
  topic = google_pubsub_topic.publish_topic.name
  role  = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}



locals {
  project = var.projectID
}

resource "google_storage_bucket" "bucket" {
  name                        = "${local.project}-storage-bucket" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "bucket_object" {
  name   = "cloudfunc.zip"
  bucket = google_storage_bucket.bucket.name
  source = "cloudfunc.zip" # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "cloud_function" {
  name        = "verify-user-cloud-function"
  location    = var.region
  description = "a function to be triggered on user creation and send a verification link to the user"

  build_config {
    runtime     = "nodejs16"
    entry_point = "userCreated" # Set the entry point 
    # environment_variables = {
    #     BUILD_CONFIG_TEST = "build_test"
    # }
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.bucket_object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "4Gi"
    timeout_seconds    = 60
    available_cpu      = "4"
    vpc_connector      = google_vpc_access_connector.vpc-connector.id
    environment_variables = {
      DB_NAME     = var.db_name,
      DB_USER     = var.db_user,
      DB_PASSWORD = random_password.user_password.result,
      HOST        = google_sql_database_instance.postgres_db_instance.private_ip_address,
      DIALECT     = var.dialect,
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.publish_topic.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
  depends_on = [google_vpc_access_connector.vpc-connector]
}

resource "google_cloudfunctions2_function_iam_binding" "bindingCF" {
  location       = google_cloudfunctions2_function.cloud_function.location
  cloud_function = google_cloudfunctions2_function.cloud_function.name
  role           = "roles/viewer"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
  depends_on = [google_cloudfunctions2_function.cloud_function]
}

resource "google_vpc_access_connector" "vpc-connector" {
  name          = "vpc-connector"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.virtual_private_cloud.id
}
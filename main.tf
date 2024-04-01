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
resource "google_compute_firewall" "allow_vpc_connector_to_dbinstance_rule" {
  name               = var.firewall_Rule_5
  network            = google_compute_network.virtual_private_cloud.name
  direction          = "EGRESS"
  destination_ranges = [google_sql_database_instance.postgres_db_instance.private_ip_address]
  source_ranges      = [var.firewall_5_source_ranges]
  allow {
    protocol = var.firewall_5_protocol
    ports    = [var.firewall_5_port]
  }
  priority = 1001
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



# resource "google_compute_instance" "web_instance" {
#   name         = var.google_compute_instance_name
#   machine_type = var.google_compute_instance_machine_type


#   metadata_startup_script = <<-EOT
# #!/bin/bash

# cd /home/Cloud/webapp/ || exit

# env_values=$(cat <<EOF
# PORT=${var.port}
# DB_NAME=${var.db_name}
# DB_USER=${var.db_user}
# DB_PASSWORD=${random_password.user_password.result}
# HOST=${google_sql_database_instance.postgres_db_instance.private_ip_address}
# DIALECT=${var.dialect}
# NODE_ENV=PROD
# LINK_EXPIRATION_TIME=${var.link_expiration_time}
# EOF
# )
# echo "$env_values" | sudo tee .env >/dev/null
# sudo chown csye6225:csye6225 .env 
# echo ".env file created"

# EOT
#   boot_disk {
#     initialize_params {
#       image = var.machine_image_name
#       size  = var.disk_size
#       type  = var.disk_type
#     }
#   }
#   network_interface {
#     network    = google_compute_network.virtual_private_cloud.id
#     subnetwork = google_compute_subnetwork.subnet_1.id
#     access_config {
#       network_tier = var.network_interface_network_tier
#     }
#   }

#   allow_stopping_for_update = true

#   service_account {
#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     email  = google_service_account.service_account.email
#     scopes = ["logging-write", "monitoring-write", "pubsub"]
#   }

#   depends_on = [
#     google_compute_network.virtual_private_cloud,
#     google_compute_firewall.allow_traffic_to_port_rule,
#     google_compute_firewall.deny_traffic_to_ssh_rule,
#     google_service_account.service_account
#   ]
#   tags = ["web-instance"]
# }


resource "google_compute_region_instance_template" "web_instance_template" {
  name        = "web-instance-template"
  description = "This template is used to create web instances depending on the load"

  machine_type   = var.google_compute_instance_machine_type
  can_ip_forward = false

  scheduling {
    automatic_restart = true
  }

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
LINK_EXPIRATION_TIME=${var.link_expiration_time}
EOF
)
echo "$env_values" | sudo tee .env >/dev/null
sudo chown csye6225:csye6225 .env 
echo ".env file created"

EOT
  // Create a new boot disk from an image
  disk {
    source_image = var.machine_image_name
    auto_delete  = true
    boot         = true
    type         = var.disk_type
  }

  network_interface {
    network    = google_compute_network.virtual_private_cloud.id
    subnetwork = google_compute_subnetwork.subnet_1.id
    access_config {
      network_tier = var.network_interface_network_tier
    }
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["logging-write", "monitoring-write", "pubsub"]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_network.virtual_private_cloud,
    google_compute_firewall.allow_traffic_to_port_rule,
    google_compute_firewall.deny_traffic_to_ssh_rule,
    google_service_account.service_account
  ]

  tags = ["web-instance"]
}

resource "google_compute_health_check" "http_health_check" {
  name        = "http-health-check"
  description = "Health check via http"


  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 3
  unhealthy_threshold = 4

  http_health_check {
    port         = var.port
    request_path = "/healthz"
    proxy_header = "NONE"
  }
}
resource "google_compute_region_instance_group_manager" "webapp_instance_group_manager" {
  name = "webapp-instance-group-manager"

  base_instance_name        = "webapp-base-instance"
  region                    = var.region
  distribution_policy_zones = [var.zone]

  version {
    instance_template = google_compute_region_instance_template.web_instance_template.self_link
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http_health_check.id
    initial_delay_sec = 300
  }
  named_port {
    name = "http"
    port = 3001
  }
  depends_on = [google_compute_health_check.http_health_check]
}

resource "google_compute_region_autoscaler" "webapp_instance_region_autoscaler" {
  name   = "webapp-instance-region-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_instance_group_manager.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.05
    }
  }
  depends_on = [google_compute_region_instance_group_manager.webapp_instance_group_manager]
}

module "loadbalancer" {
  source  = "terraform-google-modules/lb-http/google"
  version = "~> 10.0"
  name    = "loadbalancer"
  project = var.projectID

  # firewall_networks = [google_compute_network.default.name]
  ssl                             = true
  managed_ssl_certificate_domains = ["payalkhatri.me"]
  # https_redirect                  = true
  # labels                          = { "example-label" = "cloud-run-example" }
  backends = {
    default = {

      protocol    = "HTTP"
      port        = 3001
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/healthz"
        port         = 3001
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group = google_compute_region_instance_group_manager.webapp_instance_group_manager.instance_group
        },
      ]

      iap_config = {
        enable = false
      }
    }
  }
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

  //rrdatas    = [google_compute_instance.web_instance.network_interface[0].access_config[0].nat_ip]
  rrdatas = [module.loadbalancer.external_ip]
  //depends_on = [google_compute_instance.web_instance]

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

resource "google_project_iam_binding" "binding_pubsub_publisher_for_webapp" {
  project = var.projectID
  role    = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
  depends_on = [google_service_account.service_account]
}

resource "google_service_account" "service_account_for_cloud_function" {
  account_id                   = var.google_service_CF_account_id
  display_name                 = var.google_service__CF_account_name
  create_ignore_already_exists = true
}


resource "google_project_iam_binding" "binding_cloud_function_invoker" {
  project = var.projectID
  role    = "roles/run.invoker"

  members = [
    "serviceAccount:${google_service_account.service_account_for_cloud_function.email}"
  ]
  depends_on = [google_service_account.service_account_for_cloud_function]
}
resource "google_pubsub_topic" "publish_topic" {
  name                       = var.publish_topic_name
  message_retention_duration = var.pubsub_message_retention_duration
}

resource "google_pubsub_subscription" "pubsub_subscription" {
  name  = var.pubsub_subscription_name
  topic = google_pubsub_topic.publish_topic.id

  message_retention_duration = var.pubsub_message_retention_duration
  push_config {
    push_endpoint = google_cloudfunctions2_function.cloud_function.service_config[0].uri
    oidc_token {
      service_account_email = google_service_account.service_account_for_cloud_function.email
    }
  }
  depends_on = [google_pubsub_topic.publish_topic, google_cloudfunctions2_function.cloud_function, google_service_account.service_account_for_cloud_function]
}



locals {
  project = var.projectID
}


data "google_storage_bucket" "cloud_function_bucket_webapp" {
  name = var.google_storage_bucket_name
}

data "google_storage_bucket_object" "cloud_function_bucket_webapp_object" {
  bucket     = data.google_storage_bucket.cloud_function_bucket_webapp.name
  name       = var.bucket_object_file_name
  depends_on = [data.google_storage_bucket.cloud_function_bucket_webapp]
}
resource "google_cloudfunctions2_function" "cloud_function" {
  name        = var.cloud_function_name
  location    = var.region
  description = "a function to be triggered on user creation and send a verification link to the user"

  build_config {
    runtime     = "nodejs16"
    entry_point = var.cloud_function_entry_point
    source {
      storage_source {
        bucket = data.google_storage_bucket.cloud_function_bucket_webapp.name
        object = data.google_storage_bucket_object.cloud_function_bucket_webapp_object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = var.cloud_function_available_memory
    timeout_seconds    = 60
    available_cpu      = var.cloud_function_available_cpu
    vpc_connector      = google_vpc_access_connector.vpc-connector.id
    environment_variables = {
      DB_NAME               = var.db_name,
      DB_USER               = var.db_user,
      DB_PASSWORD           = random_password.user_password.result,
      HOST                  = google_sql_database_instance.postgres_db_instance.private_ip_address,
      DIALECT               = var.dialect,
      service_account_email = google_service_account.service_account_for_cloud_function.email

    }

  }

  depends_on = [google_vpc_access_connector.vpc-connector, google_service_account.service_account_for_cloud_function, google_sql_database_instance.postgres_db_instance, data.google_storage_bucket_object.cloud_function_bucket_webapp_object]
}


resource "google_vpc_access_connector" "vpc-connector" {
  name          = var.vpc_connector_name
  ip_cidr_range = var.vpc_connector_cidr_range
  network       = google_compute_network.virtual_private_cloud.id
  depends_on    = [google_compute_network.virtual_private_cloud]
}

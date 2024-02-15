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

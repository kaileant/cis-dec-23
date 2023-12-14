variable "zone" {
  default = "us-central1-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project = "hotdawg"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "firewall" {
  name    = "terraform-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  target_tags = ["web"]
  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["dev", "web"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      # image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}

output "internal_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}

output "external_ip" {
value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
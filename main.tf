variable "zone" {
  default = "us-central1-a"
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
  machine_type = "e2-medium"
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

resource "google_service_account" "service_account" {
  account_id   = "killua"
  display_name = "hunter"
  project = "hotdawg"
}

resource "google_compute_disk" "default" {
  name  = "tform-disk-wwwdata"
  type  = "pd-standard"
  zone  = "us-central1-a"
  image = "debian-11-bullseye-v20220719"
  labels = {
    environment = "dev"
  }
  physical_block_size_bytes = 4096
}

resource "google_storage_bucket" "backup-bucket" {
  name          = "kt-bucket"
  location      = "us"
  project = "hotdawg"
  force_destroy = true
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      with_state = "ARCHIVED"
      num_newer_versions = 180
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 180
    }
    action {
      type = "Delete"
    }
  }
}  

resource "google_storage_bucket_iam_member" "backup-bucket" {
 bucket = google_storage_bucket.backup-bucket.name
 role  = "roles/storage.objectViewer"
 member = "allUsers"
}


output "internal_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}

output "external_ip" {
value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
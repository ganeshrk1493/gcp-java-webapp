terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Enable APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# 2. Artifact Registry Repository
resource "google_artifact_registry_repository" "webapp_repo" {
  location      = var.region
  repository_id = "webapp-repo"
  description   = "Docker images for Java Cloud Run apps"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# 3. Service Accounts (Deployer for Jenkins, Runtime for Cloud Run)
resource "google_service_account" "jenkins_deployer" {
  account_id   = "sa-jenkins-webapp-deployer"
  display_name = "Jenkins Cloud Run Deployer"
}

resource "google_service_account" "webapp_runtime" {
  account_id   = "sa-webapp-runtime"
  display_name = "Cloud Run Webapp Runtime"
}

# 4. IAM Bindings
resource "google_project_iam_member" "deployer_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.jenkins_deployer.email}"
}

resource "google_project_iam_member" "deployer_run_admin" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.jenkins_deployer.email}"
}

resource "google_service_account_iam_member" "deployer_act_as_runtime" {
  service_account_id = google_service_account.webapp_runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.jenkins_deployer.email}"
}

# 5. Firewall for Jenkins Port 8080
resource "google_compute_firewall" "jenkins_http" {
  name    = "allow-jenkins-8080"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jenkins-server"]
}

# 6. Jenkins Compute Engine VM
resource "google_compute_instance" "jenkins_vm" {
  name         = "jenkins-webapp-vm"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["jenkins-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = google_service_account.jenkins_deployer.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y fontconfig openjdk-21-jre docker.io git curl gnupg

    # Install Jenkins
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update -y
    apt-get install -y jenkins

    # Allow Jenkins to run Docker commands without sudo
    usermod -aG docker jenkins
    systemctl enable docker jenkins
    systemctl restart docker jenkins
  EOF

  depends_on = [google_project_service.apis]
}
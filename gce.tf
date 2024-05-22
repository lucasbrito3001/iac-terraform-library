# resource "google_service_account" "gce_svc_acc" {
#   account_id   = "svc_acc_terraform"
#   display_name = "Custom SA for VM Instance"
# }

resource "google_compute_instance" "services_instance" {
  name                      = "services-instance"
  machine_type              = var.services_machine_type
  zone                      = var.zone
  project                   = var.project_id
  allow_stopping_for_update = true

  tags = ["dev-instances", "allow-ssh", "allow-http", "allow-health-checks"]

  boot_disk {
    initialize_params {
      image = var.services_machine_image
      size  = 100
      type  = "pd-ssd"
    }
  }

  network_interface {
    network            = google_compute_network.main_vpc_network.name
    subnetwork         = google_compute_subnetwork.main_vpc_subnetwork.name
    subnetwork_project = var.project_id
  }

  metadata_startup_script = file("scripts/start_script.sh")
}

resource "google_compute_instance_group" "services_instance_group" {
  name = "services-instance-group"

  instances = [
    google_compute_instance.services_instance.self_link,
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }

  zone = var.zone
}

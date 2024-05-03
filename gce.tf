# resource "google_service_account" "gce_svc_acc" {
#   account_id   = "svc_acc_terraform"
#   display_name = "Custom SA for VM Instance"
# }

resource "google_compute_instance" "dev_services_instance" {
  count        = 1
  name         = "dev-services-cluster-vm-${count.index + 1}"
  machine_type = var.services_machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["dev-instances", "allow-ssh", "allow-http", "allow-docker-swarm"]

  boot_disk {
    initialize_params {
      image = var.services_machine_image
      size  = 10
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network            = google_compute_network.main_vpc_network.name
    subnetwork         = google_compute_subnetwork.dev_vpc_subnetwork.name
    subnetwork_project = var.project_id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash

    # Update the package index
    sudo apt update

    # Install dependencies
    sudo apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker’s official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up the stable repository
    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update the package index again
    sudo apt update

    # Install Docker Engine
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # Check Docker version
    sudo docker --version

    # Add your user to the docker group
    sudo usermod -aG docker $USER

    # Enable Docker service to start on boot
    sudo systemctl enable docker

    echo "Docker has been installed successfully."
  EOF
}
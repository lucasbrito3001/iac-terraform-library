resource "google_compute_network" "main_vpc_network" {
  name                    = "main-vpc-network"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "main_vpc_subnetwork" {
  name          = "main-vpc-subnetwork"
  network       = google_compute_network.main_vpc_network.name
  ip_cidr_range = var.subnet_ip_range
  project       = var.project_id
  region        = var.region
}

resource "google_compute_router" "main_router" {
  name    = "main-router"
  region  = var.region
  network = google_compute_network.main_vpc_network.name

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "main_router_nat" {
  name                               = "main-router-nat"
  router                             = google_compute_router.main_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name      = "allow-ssh"
  project   = var.project_id
  network   = google_compute_network.main_vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-ssh"]
}

resource "google_compute_firewall" "allow_docker_swarm" {
  name      = "allow-docker-swarm"
  project   = var.project_id
  network   = google_compute_network.main_vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["2377"]
  }

  source_tags = ["allow-docker-swarm"]
  target_tags = ["allow-docker-swarm"]
}

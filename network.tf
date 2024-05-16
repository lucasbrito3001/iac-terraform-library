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

resource "google_compute_firewall" "allow_http" {
  name      = "allow-http"
  project   = var.project_id
  network   = google_compute_network.main_vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [google_compute_global_address.l7_lb_static_ip.address]
  target_tags   = ["allow-http"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name      = "allow-health-checks"
  project   = var.project_id
  network   = google_compute_network.main_vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["allow-health-checks"]
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

# reserved IP address
resource "google_compute_global_address" "l7_lb_static_ip" {
  name = "l7-lb-static-dip"
}

# forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "l7-xlb-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.l7_lb_target_http_proxy.id
  ip_address            = google_compute_global_address.l7_lb_static_ip.id
}

# http proxy
resource "google_compute_target_http_proxy" "l7_lb_target_http_proxy" {
  name    = "l7-lb-target-http-proxy"
  url_map = google_compute_url_map.l7_lb_url_map.id
}

# url map
resource "google_compute_url_map" "l7_lb_url_map" {
  name            = "l7-lb-url-map"
  default_service = google_compute_backend_service.l7_lb_backend_service.id
}

# backend service with custom request and response headers
resource "google_compute_backend_service" "l7_lb_backend_service" {
  name                  = "l7-lb-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 10
  enable_cdn            = true
  health_checks         = [google_compute_health_check.l7_lb_hc.id]
  backend {
    group           = google_compute_instance_group.services_instance_group.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# health check
resource "google_compute_health_check" "l7_lb_hc" {
  name = "l7-lb-hc"
  http_health_check {
    port_specification = "USE_FIXED_PORT"
  }
}

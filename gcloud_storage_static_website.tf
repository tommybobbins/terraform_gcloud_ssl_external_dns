resource "google_storage_bucket" "static_site" {
  name          = local.domain_name
  location      = "EU"
  force_destroy = true
  uniform_bucket_level_access = true
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  cors {
    origin          = ["https://${var.domain_name}","http://${var.domain_name}"]
    method          = ["GET", "HEAD", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# External IP Address for load balancer
resource "google_compute_global_address" "static" {
  name        = "static"
  description = "Static external IP address for hosting"
}

resource "google_certificate_manager_certificate" "default" {
  name        = "wildcard-chegwin-org"
  project     = var.project
  scope       = "DEFAULT"
  managed {
    domains   = ["*.chegwin.org"]
  } 
}


#data "google_certificate_manager_certificate" "default" {
#  name = "wildcard-chegwin-org"
#  project = var.project
#}

# SSL Policies
resource "google_compute_ssl_policy" "tls12_modern" {
  name            = "${var.env}-static-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

# HTTPS load balancer for backend bucket
resource "google_compute_backend_bucket" "static" {
  name        = "${var.env}-static-backend"
  description = "Backend storage bucket for statick static files"
#  bucket_name = "${var.env}-static"
  bucket_name = google_storage_bucket.static_site.name
  # bucket_name = module.cloud_storage_buckets.google_storage_bucket.buckets["static"].name
  enable_cdn = false
}

resource "google_compute_url_map" "static" {
  name            = "${var.env}-static-load-balancer"
  default_service = google_compute_backend_bucket.static.id
}

resource "google_compute_target_https_proxy" "static" {
  name             = "${var.env}-proxy-static"
  url_map          = google_compute_url_map.static.id
  ssl_certificates = [google_certificate_manager_certificate.default.id]
  ssl_policy       = google_compute_ssl_policy.tls12_modern.id
}

resource "google_compute_global_forwarding_rule" "static" {
  name       = "${var.env}-forwarding-static"
  target     = google_compute_target_https_proxy.static.id
  port_range = "443"
  ip_address = google_compute_global_address.static.id
}

# Partial HTTP load balancer redirects to HTTPS
resource "google_compute_url_map" "static_http" {
  name = "${var.env}-static-http-redirect"
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "static" {
  name    = "${var.env}-static-http-proxy"
  url_map = google_compute_url_map.static_http.id
}

resource "google_compute_global_forwarding_rule" "static_http" {
  name       = "${var.env}-static-forwarding-rule-http"
  target     = google_compute_target_http_proxy.static.id
  port_range = "80"
  ip_address = google_compute_global_address.static.id
}

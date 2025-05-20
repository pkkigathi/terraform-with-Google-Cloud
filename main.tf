# Create GCS bucket for the website
resource "google_storage_bucket" "website" {
  name     = "example-website-by-peter"
  location = "US"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# Upload all static files from the website/ folder
locals {
  website_files = fileset("${path.module}/website", "*")
}

resource "google_storage_bucket_object" "static_site_assets" {
  for_each     = { for file in local.website_files : file => file }
  name         = each.key
  source       = "${path.module}/website/${each.value}"
  bucket       = google_storage_bucket.website.name
  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
  }, split(".", each.key)[length(split(".", each.key)) - 1], "application/octet-stream")
}

# Make the uploaded files public
resource "google_storage_object_access_control" "public_rule" {
  for_each = google_storage_bucket_object.static_site_assets

  object = each.value.name
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

# Reserve a static external IP address
resource "google_compute_global_address" "website_ip" {
  name = "website-lb-ip"
}

# Get the IP-managed DNS Zone
data "google_dns_managed_zone" "dns_zone" {
  name = "terraform-gcp"
}

# Add the IP to DNS
resource "google_dns_record_set" "website" {
  name         = "website.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}

# Backend bucket with CDN
resource "google_compute_backend_bucket" "website_backend" {
  name        = "website-bucket"
  bucket_name = google_storage_bucket.website.name
  description = "Contains files needed for the website"
  enable_cdn  = true
}

# URL Map
resource "google_compute_url_map" "website" {
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website_backend.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website_backend.self_link
  }
}

# GCP HTTP Proxy
resource "google_compute_target_http_proxy" "website" {
  name    = "website-target-proxy"
  url_map = google_compute_url_map.website.self_link
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website_ip.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.website.self_link
}

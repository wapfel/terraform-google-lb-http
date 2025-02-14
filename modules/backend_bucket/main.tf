/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


locals {
  address             = var.create_address ? join("", google_compute_global_address.default.*.address) : var.address
  ipv6_address        = var.create_ipv6_address ? join("", google_compute_global_address.default_ipv6.*.address) : var.ipv6_address
  url_map             = var.create_url_map ? join("", google_compute_url_map.default.*.self_link) : var.url_map
  create_http_forward = var.http_forward || var.https_redirect

}

### IPv4 block ###
resource "google_compute_global_forwarding_rule" "http" {
  project    = var.project
  count      = local.create_http_forward ? 1 : 0
  name       = var.name
  target     = google_compute_target_http_proxy.default[0].self_link
  ip_address = local.address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "https" {
  project    = var.project
  count      = var.ssl ? 1 : 0
  name       = "${var.name}-https"
  target     = google_compute_target_https_proxy.default[0].self_link
  ip_address = local.address
  port_range = "443"
}

resource "google_compute_global_address" "default" {
  count      = var.create_address ? 1 : 0
  project    = var.project
  name       = "${var.name}-address"
  ip_version = "IPV4"
}
### IPv4 block ###

### IPv6 block ###
resource "google_compute_global_forwarding_rule" "http_ipv6" {
  project    = var.project
  count      = (var.enable_ipv6 && local.create_http_forward) ? 1 : 0
  name       = "${var.name}-ipv6-http"
  target     = google_compute_target_http_proxy.default[0].self_link
  ip_address = local.ipv6_address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "https_ipv6" {
  project    = var.project
  count      = (var.enable_ipv6 && var.ssl) ? 1 : 0
  name       = "${var.name}-ipv6-https"
  target     = google_compute_target_https_proxy.default[0].self_link
  ip_address = local.ipv6_address
  port_range = "443"
}

resource "google_compute_global_address" "default_ipv6" {
  count      = (var.enable_ipv6 && var.create_ipv6_address) ? 1 : 0
  project    = var.project
  name       = "${var.name}-ipv6-address"
  ip_version = "IPV6"
}
### IPv6 block ###

# HTTP proxy when http forwarding is true
resource "google_compute_target_http_proxy" "default" {
  project = var.project
  count   = local.create_http_forward ? 1 : 0
  name    = "${var.name}-http-proxy"
  url_map = var.https_redirect == false ? local.url_map : join("", google_compute_url_map.https_redirect.*.self_link)
}

# HTTPS proxy when ssl is true
resource "google_compute_target_https_proxy" "default" {
  project = var.project
  count   = var.ssl ? 1 : 0
  name    = "${var.name}-https-proxy"
  url_map = local.url_map

  ssl_certificates = compact(concat(var.ssl_certificates, google_compute_ssl_certificate.default.*.self_link, google_compute_managed_ssl_certificate.default.*.self_link, ), )
  ssl_policy       = var.ssl_policy
  quic_override    = var.quic ? "ENABLE" : null
}

resource "google_compute_ssl_certificate" "default" {
  project     = var.project
  count       = var.ssl && length(var.managed_ssl_certificate_domains) == 0 && !var.use_ssl_certificates ? 1 : 0
  name_prefix = "${var.name}-certificate-"
  private_key = var.private_key
  certificate = var.certificate

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_id" "certificate" {
  count       = var.random_certificate_suffix == true ? 1 : 0
  byte_length = 4
  prefix      = "${var.name}-cert-"

  keepers = {
    domains = join(",", var.managed_ssl_certificate_domains)
  }
}

resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  project  = var.project
  count    = var.ssl && length(var.managed_ssl_certificate_domains) > 0 && !var.use_ssl_certificates ? 1 : 0
  name     = var.random_certificate_suffix == true ? random_id.certificate[0].hex : "${var.name}-cert"

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = var.managed_ssl_certificate_domains
  }
}

resource "google_compute_url_map" "default" {
  project         = var.project
  count           = var.create_url_map ? 1 : 0
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_bucket.default[keys(var.buckets)[0]].self_link
}

resource "google_compute_url_map" "https_redirect" {
  project = var.project
  count   = var.https_redirect ? 1 : 0
  name    = "${var.name}-https-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_backend_bucket" "default" {
  provider = google-beta
  for_each = var.buckets

  project     = var.project
  name        = "${var.name}-backend-bucket-${each.key}"
  description = lookup(each.value, "description", null)
  bucket_name = each.value.bucket_name
  enable_cdn  = var.cdn

  cdn_policy {
    cache_mode                   = lookup(each.value, "cache_mode", "CACHE_ALL_STATIC")
    client_ttl                   = lookup(each.value, "client_ttl", 3600)
    default_ttl                  = lookup(each.value, "default_ttl", 3600)
    max_ttl                      = lookup(each.value, "max_ttl", 86400)
    negative_caching             = lookup(each.value, "negative_caching", false)
    signed_url_cache_max_age_sec = lookup(each.value, "signed_url_cache_max_age_sec", 7200)
  }
}


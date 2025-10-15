resource "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.region
  remove_default_node_pool = true
  network  = "default"
  subnetwork = "default"
  release_channel { channel = "REGULAR" }
}

resource "google_container_node_pool" "default" {
  name       = "default"
  location   = var.region
  cluster    = google_container_cluster.this.name
  node_count = 3
  node_config { machine_type = "e2-standard-4" }
}

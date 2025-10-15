output "cluster_name" { value = google_container_cluster.this.name }
output "kubeconfig"   { value = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --region ${var.region}" }

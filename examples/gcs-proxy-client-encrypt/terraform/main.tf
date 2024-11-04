data "google_project" "project" {
  project_id = var.project_id
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 33.0"

  project_id              = var.project_id
  name                    = var.name
  regional                = false
  zones                   = var.zones
  network                 = var.network
  subnetwork              = var.subnetwork
  ip_range_pods           = var.ip_range_pods
  ip_range_services       = var.ip_range_services
  create_service_account  = true
  enable_private_endpoint = false
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.27.0.0/28"
  deletion_protection     = false
}

module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "~> 3.0"

  project_id = var.project_id
  keyring    = var.keyring
  location   = var.location
  keys       = var.keys
  # keys can be destroyed by Terraform
  prevent_destroy = false
}

module "projects_iam_bindings" {
  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 8.0"

  projects = [var.project_id]

  bindings = {
    "roles/storage.admin" = [
      "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/mitmproxy-demo/sa/gcs-proxy-sa",
    ]

    "roles/cloudkms.cryptoKeyDecrypter" = [
      "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/mitmproxy-demo/sa/gcs-proxy-sa",
    ]

    "roles/cloudkms.cryptoKeyEncrypter" = [
      "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/mitmproxy-demo/sa/gcs-proxy-sa",
    ]
  }
}

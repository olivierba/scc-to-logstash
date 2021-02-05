
resource "google_service_account" "sa-logstash" {
  account_id   = "sa-logstash"
  display_name = "Logstash VM service account"
}

#need permission to access Pubsub topic
data "google_iam_policy" "scc-computeservice-iam" {
    binding {
        role = "roles/iam.serviceAccountUser"

        members = [
            "serviceAccount:${var.scc-sa}",
        ]
    }
}

resource "google_service_account_iam_policy" "scc-account-iam" {
    service_account_id = google_service_account.sa-logstash.name
    policy_data        = data.google_iam_policy.scc-computeservice-iam.policy_data
}

data "google_iam_policy" "scc-pubsub-topic-editor" {
  binding {
    role = "roles/editor"
    members = [
      "serviceAccount:${var.scc-sa}",
    ]
  }
}

resource "google_pubsub_topic_iam_policy" "policy" {
  project = var.project
  topic = var.topic
  policy_data = data.google_iam_policy.scc-pubsub-topic-editor.policy_data
}

#this bucket will contain the logstash pipeline config file. The VM will pull this config upon startup
resource "google_storage_bucket" "logstash-config" {
  name          = "${var.project}-logstash-config"
  location      = "EU"
  force_destroy = true
}

#uploading the file
resource "google_storage_bucket_object" "logstash-config-file" {
  name   = "scc-pipeline.conf"
  source = "scc-pipeline.conf"
  bucket = google_storage_bucket.logstash-config.id 
}

#iam permission on the bucket to the service account
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.logstash-config.id 
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${var.scc-sa}"
}

resource "google_compute_instance" "vm_logstash" {
    name         = "logstash-collector"
    machine_type = "e2-standard-2"
    zone         = var.zone

    boot_disk {
        initialize_params {
            size = 30
            image = "debian-cloud/debian-10"
        }
    }

    network_interface {
        # A default network is created for all GCP projects
        network = "default"
        access_config {
        }
    }

    metadata_startup_script = file("logstash-install.sh")

    service_account {
        email  = var.scc-sa
        scopes = ["cloud-platform"]
    }
}

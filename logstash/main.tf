
resource "google_service_account" "sa-logstash" {
  account_id   = "sa-logstash"
  display_name = "Logstash VM service account"
}

#need permission to access Pubsub topic and dl config file on cloud storage bucket
data "google_iam_policy" "scc-computeservice-iam" {
    binding {
        role = "roles/iam.serviceAccountUser"

        members = [
            "user:${var.scc-sa}",
        ]
    }
    binding {
        role = "roles/storage.objectViewer"
        members = [
            "user:${var.scc-sa}",
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
      "user:${var.scc-sa}",
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
  name          = "logstash-config"
  location      = "EU"
  force_destroy = true
}

resource "google_storage_bucket_object" "logstash-config-file" {
  name   = "scc-pipeline.conf"
  source = "scc-pipeline.conf"
  bucket = "logstash-config"
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

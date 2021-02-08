
#creating service account

resource "google_service_account" "sa-logstash" {
  account_id   = "sa-logstash"
  display_name = "Logstash VM service account"
}

#generating key for sc (using the compute account sa identity did not work)
resource "google_service_account_key" "sa-logstash-key" {
  service_account_id = google_service_account.sa-logstash.name
  public_key_type    = "TYPE_X509_PEM_FILE"
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

#iam permission on the subscription
resource "google_pubsub_subscription_iam_binding" "editor" {
  subscription = var.subscription
  role         = "roles/editor"
  members = [
    "serviceAccount:${var.scc-sa}",
  ]
}

#this bucket will contain the logstash pipeline config file. The VM will pull this config upon startup, the bucket will also contain the service account key (with proper acl)
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

#uploading the service account key to the bucket as well
resource "google_storage_bucket_object" "sa-logstash-key-file" {
  name   = "sa-logstash-key.json"
  content = base64decode(google_service_account_key.sa-logstash-key.private_key)
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

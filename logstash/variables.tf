variable "scc-sa" {
  default = "sc-logstash@projectid.iam.gserviceaccount.com"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "topic" {
  default = "pubsubtopic"
}

variable "project" {
  description = "What is the name of the project you would like resources to be created under in GCP?"
}

variable "gcp_key_filename" {
  description = "What's the json key filename located in your <home>/.gcloud/ directory path?"
  default = "key.json"
}
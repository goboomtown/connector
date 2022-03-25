# Before using terraform with Google Cloud you need to authenticate to it:
#
#   gcloud auth application-default login
#
# Using terraform:
#
#   terraform init
#   terraform plan
#   terraform apply (to setup)
#   terraform destroy (to tear down)

terraform {
  required_version = ">= 0.14"

  required_providers {
    # Cloud Run support was added on 3.3.0
    google = ">= 3.3"
  }
}

provider "google" {
  project = var.project
}

data "github_user" "current" {
  username = "lborsato"
}

resource "github_repository" "connector" {
  name         = "connector"
  description  = "Connector Example"

  visibility = "public"

  template {
    owner      = "goboomtown"
    repository = "example-connector-transactions-ts"
  }

}

resource "github_branch" "development" {
  repository = "connector"
  branch     = var.branch_name
}

resource "github_repository_environment" "connector" {
  environment  = "connector"
  repository   = github_repository.connector.name
  reviewers {
    users = [data.github_user.current.id]
  }
  deployment_branch_policy {
    protected_branches          = true
    custom_branch_policies = false
  }
}

#resource "google_sourcerepo_repository" "repo" {
#  name = var.repository_name
#}


# Create a Cloud Build trigger
resource "google_cloudbuild_trigger" "cloud_build_trigger" {
  provider    = "google-beta"
  description = "Cloud Source Repository Trigger github_repository.connector.name (${var.branch_name})"

  trigger_template {
    branch_name = var.branch_name
    repo_name   = github_repository.connector.name
  }

#  github {
#    owner = var.github_owner
#    name  = var.github_repository
#    push {
#      branch = var.branch_name
#    }
#  }

  # These substitutions have been defined in the sample app's cloudbuild.yaml file.
  # See: https://github.com/gruntwork-io/sample-app-docker/blob/master/cloudbuild.yaml#L40
  substitutions = {
    _GCR_REGION = var.region
  }

  # The filename argument instructs Cloud Build to look for a file in the root of the repository.
  # Either a filename or build template (below) must be provided.
  filename = "cloudbuild.yaml"
  
  depends_on = [github_repository.connector]
}

# Enables the Cloud Run API
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"

  disable_on_destroy = true
}

# Create the Cloud Run service
resource "google_cloud_run_service" "run_service" {
  name = "app"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/google-samples/hello-app:1.0"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  # Waits for the Cloud Run API to be enabled
  depends_on = [google_project_service.run_api]
}

# Allow unauthenticated users to invoke the service
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.run_service.name
  location = google_cloud_run_service.run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Display the service URL
output "service_url" {
  value = google_cloud_run_service.run_service.status[0].url
}


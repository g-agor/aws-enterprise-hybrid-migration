
terraform {
  backend "s3" {
    bucket       = "project3-hybrid-terraform-state-euw2"
    key          = "development/terraform.tfstate"
    region       = "eu-west-2"
    profile      = "T-Builder"
    encrypt      = true
    use_lockfile = true
  }
}

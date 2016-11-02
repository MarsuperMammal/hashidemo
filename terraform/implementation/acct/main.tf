variable "cloud_trail_bucket" {}
variable "trailname" { default = "default" }
variable "region" {}

provider "aws" {
  region = "${var.region}"
}

module "acct" {
  source = "../../modules/acct"
  cloud_trail_bucket = "${var.cloud_trail_bucket}"
  trailname = "${var.trailname}"
}

output "flowlogrole" { value = "${module.acct.flowlogrole}" }

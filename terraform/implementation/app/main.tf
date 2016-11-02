variable "region" {}
variable "key_name" {}
variable "atlas_infrastructure" {}
variable "atlas_token" {}
variable "proxy_asg_max" { default = 5 }
variable "proxy_asg_min" { default = 3 }
variable "proxy_asg_desired" { default = 3 }
variable "proxy_app_name" { default = "proxy" }
variable "proxy_ami_id" {}
variable "proxy_instance_type" {}
variable "proxy_scaleup_cpu_threshold_value" { default = "90" }
variable "proxy_scaledown_cpu_threshold_value" { default = "10" }
variable "websvcs_asg_max" { default = 5 }
variable "websvcs_asg_min" { default = 3 }
variable "websvcs_asg_desired" { default = 3 }
variable "websvcs_app_name" { default = "websvcs" }
variable "websvcs_ami_id" {}
variable "websvcs_instance_type" {}
variable "websvcs_scaleup_cpu_threshold_value" { default = "90" }
variable "websvcs_scaledown_cpu_threshold_value" { default = "10" }

provider "aws" {
  region = "${var.region}"
}

data "terraform_remote_state" "acct" {
  backend = "s3"
  config {
    bucket = "anatta-shared-state"
    key = "acct.tfstate"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config {
    bucket = "anatta-shared-state"
    key = "network.tfstate"
  }
}

data "terraform_remote_state" "foundation" {
  backend = "s3"
  config {
    bucket = "anatta-shared-state"
    key = "foundation.tfstate"
  }
}

data "template_file" "proxy-userdata" {
  template = "${file("templates/proxy-userdata.tpl")}"
  vars {
    aws_region = "${var.region}"
    atlas_token = "${var.atlas_token}"
    atlas_infrastructure = "${var.atlas_infrastructure}"
  }
}

data "template_file" "websvcs-userdata" {
  template = "${file("templates/websvcs-userdata.tpl")}"
  vars {
    aws_region = "${var.region}"
    atlas_token = "${var.atlas_token}"
    atlas_infrastructure = "${var.atlas_infrastructure}"
  }
}

module "proxy" {
  source = "../../modules/compute"
  region = "${var.region}"
  priv_subnets = "${data.terraform_remote_state.network.priv_subnets}"
  asg_max = "${var.proxy_asg_max}"
  asg_min = "${var.proxy_asg_min}"
  asg_desired = "${var.proxy_asg_desired}"
  key_name = "${data.terraform_remote_state.network.key_pair}"
  app_name = "${var.proxy_app_name}"
  ami_id = "${var.proxy_ami_id}"
  instance_type = "${var.proxy_instance_type}"
  asg_sgs = ["${data.terraform_remote_state.foundation.foundational-services-sg}"]
  scaleup_cpu_threshold_value = "${var.proxy_scaleup_cpu_threshold_value}"
  scaledown_cpu_threshold_value = "${var.proxy_scaledown_cpu_threshold_value}"
  userdata = "${data.template_file.proxy-userdata.rendered}"
}

module "websvcs" {
  source = "../../modules/compute"
  region = "${var.region}"
  priv_subnets = "${data.terraform_remote_state.network.priv_subnets}"
  asg_max = "${var.websvcs_asg_max}"
  asg_min = "${var.websvcs_asg_min}"
  asg_desired = "${var.websvcs_asg_desired}"
  key_name = "${data.terraform_remote_state.network.key_pair}"
  app_name = "${var.websvcs_app_name}"
  ami_id = "${var.websvcs_ami_id}"
  instance_type = "${var.websvcs_instance_type}"
  asg_sgs = ["${data.terraform_remote_state.foundation.foundational-services-sg}"]
  scaleup_cpu_threshold_value = "${var.websvcs_scaleup_cpu_threshold_value}"
  scaledown_cpu_threshold_value = "${var.websvcs_scaledown_cpu_threshold_value}"
  userdata = "${data.template_file.websvcs-userdata.rendered}"
}

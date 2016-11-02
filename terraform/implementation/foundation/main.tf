variable "region" {}
variable "key_name" {}
variable "atlas_infrastructure" {}
variable "atlas_token" {}
variable "consul_asg_max" { default = 5 }
variable "consul_asg_min" { default = 3 }
variable "consul_asg_desired" { default = 3 }
variable "consul_app_name" { default = "consul" }
variable "consul_ami_id" {}
variable "consul_instance_type" {}
variable "consul_scaleup_cpu_threshold_value" { default = "90" }
variable "consul_scaledown_cpu_threshold_value" { default = "10" }
variable "nomad_asg_max" { default = 5 }
variable "nomad_asg_min" { default = 3 }
variable "nomad_asg_desired" { default = 3 }
variable "nomad_app_name" { default = "nomad" }
variable "nomad_ami_id" {}
variable "nomad_instance_type" {}
variable "nomad_scaleup_cpu_threshold_value" { default = "90" }
variable "nomad_scaledown_cpu_threshold_value" { default = "10" }
variable "vault_asg_max" { default = 5 }
variable "vault_asg_min" { default = 3 }
variable "vault_asg_desired" { default = 3 }
variable "vault_app_name" { default = "vault" }
variable "vault_ami_id" {}
variable "vault_instance_type" {}
variable "vault_scaleup_cpu_threshold_value" { default = "90" }
variable "vault_scaledown_cpu_threshold_value" { default = "10" }

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

data "template_file" "consul-userdata" {
  template = "${file("templates/consul-userdata.tpl")}"
  vars {
    aws_region = "${var.region}"
    atlas_token = "${var.atlas_token}"
    atlas_infrastructure = "${var.atlas_infrastructure}"
  }
}

data "template_file" "nomad-userdata" {
  template = "${file("templates/nomad-userdata.tpl")}"
  vars {
    aws_region = "${var.region}"
    atlas_token = "${var.atlas_token}"
    atlas_infrastructure = "${var.atlas_infrastructure}"
  }
}

data "template_file" "vault-userdata" {
  template = "${file("templates/vault-userdata.tpl")}"
  vars {
    aws_region = "${var.region}"
    atlas_token = "${var.atlas_token}"
    atlas_infrastructure = "${var.atlas_infrastructure}"
    ssl_cert = "${file("../../../setup/secrets/vault.crt")}"
    ssl_key = "${file("../../../setup/secrets/vault.key")}"
  }
}

module "consul" {
  source = "../../modules/compute"
  region = "${var.region}"
  priv_subnets = "${data.terraform_remote_state.network.priv_subnets}"
  asg_max = "${var.consul_asg_max}"
  asg_min = "${var.consul_asg_min}"
  asg_desired = "${var.consul_asg_desired}"
  key_name = "${data.terraform_remote_state.network.key_pair}"
  app_name = "${var.consul_app_name}"
  ami_id = "${var.consul_ami_id}"
  instance_type = "${var.consul_instance_type}"
  asg_sgs = ["${aws_security_group.foundational-services.id}"]
  scaleup_cpu_threshold_value = "${var.consul_scaleup_cpu_threshold_value}"
  scaledown_cpu_threshold_value = "${var.consul_scaledown_cpu_threshold_value}"
  userdata = "${data.template_file.consul-userdata.rendered}"
}

module "nomad" {
  source = "../../modules/compute"
  region = "${var.region}"
  priv_subnets = "${data.terraform_remote_state.network.priv_subnets}"
  asg_max = "${var.nomad_asg_max}"
  asg_min = "${var.nomad_asg_min}"
  asg_desired = "${var.nomad_asg_desired}"
  key_name = "${data.terraform_remote_state.network.key_pair}"
  app_name = "${var.nomad_app_name}"
  ami_id = "${var.nomad_ami_id}"
  instance_type = "${var.nomad_instance_type}"
  asg_sgs = ["${aws_security_group.foundational-services.id}"]
  scaleup_cpu_threshold_value = "${var.nomad_scaleup_cpu_threshold_value}"
  scaledown_cpu_threshold_value = "${var.nomad_scaledown_cpu_threshold_value}"
  userdata = "${data.template_file.nomad-userdata.rendered}"
}

module "vault" {
  source = "../../modules/compute"
  region = "${var.region}"
  priv_subnets = "${data.terraform_remote_state.network.priv_subnets}"
  asg_max = "${var.vault_asg_max}"
  asg_min = "${var.vault_asg_min}"
  asg_desired = "${var.vault_asg_desired}"
  key_name = "${data.terraform_remote_state.network.key_pair}"
  app_name = "${var.vault_app_name}"
  ami_id = "${var.vault_ami_id}"
  instance_type = "${var.vault_instance_type}"
  asg_sgs = ["${aws_security_group.foundational-services.id}"]
  scaleup_cpu_threshold_value = "${var.vault_scaleup_cpu_threshold_value}"
  scaledown_cpu_threshold_value = "${var.vault_scaledown_cpu_threshold_value}"
  userdata = "${data.template_file.vault-userdata.rendered}"
}

resource "aws_security_group" "foundational-services" {
  name = "foundational-services"
  description = "Foundational Services Security Group"
  vpc_id = "${data.terraform_remote_state.network.vpc_id}"

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    security_groups = [ "${data.terraform_remote_state.network.bastionsg}" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "foundational-services-sg" { value = "${aws_security_group.foundational-services.id}"}

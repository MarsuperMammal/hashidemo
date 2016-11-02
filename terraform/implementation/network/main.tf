variable "region" {}
variable "network_name" {}
variable "flow_log_traffic_type" { default = "ALL" }
variable "key_name" { default = "replaced_by_vault" }
variable "public_key" {}
variable "my_ip" {}

provider "aws" {
  region = "${var.region}"
}

data "aws_availability_zones" "available" {}
data "terraform_remote_state" "acct" {
  backend = "s3"
  config {
    bucket = "anatta-shared-state"
    key = "acct.tfstate"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = [ "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
  owners = ["099720109477"] # Canonical
}

module "network" {
  source = "../../modules/network"
  region = "${var.region}"
  network_name = "${var.network_name}"
  flowlogrole = "${data.terraform_remote_state.acct.flowlogrole}"
  azs = "${data.aws_availability_zones.available.names}"
  key_name = "${var.key_name}"
  my_ip = "${var.my_ip}"
  bastion_ami = "${data.aws_ami.ubuntu.id}"
}

resource "aws_key_pair" "keypair" {
  key_name = "${var.key_name}"
  public_key = "${var.public_key}"
}

output "pub_subnets" { value = "${module.network.pub_subnets}" }
output "priv_subnets" { value = "${module.network.priv_subnets}" }
output "vpc_id" { value = "${module.network.vpc_id}" }
output "bastionsg" { value = "${module.network.bastionsg}" }
output "bastion" { value = "${module.network.bastion}" }
output "key_pair" { value = "${aws_key_pair.keypair.key_name}" }

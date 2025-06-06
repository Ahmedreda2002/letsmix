/* ───── Network ───── */
module "network" {
  source   = "./modules/network"
  wlz_name = var.wlz_name
  project  = var.project
  env      = var.env
}

/* ───── Compute (EC2 front end) ───── */
module "compute" {
  source        = "./modules/compute"
  public_subnet = module.network.public_subnet_ids[0]
  key_name      = aws_key_pair.ci.key_name
  ami_id        = var.ami_id
  instance_type = var.instance_type
  project       = var.project
  env           = var.env
  domain        = var.domain
  # 👉 no sg_id argument anymore
}


/* ───── Storage (S3 artifacts) ───── */
module "storage" {
  source  = "./modules/storage"
  project = var.project
  env     = var.env
}

/* ───── DNS (public hosted zone) ───── */
module "dns" {
  source = "./modules/dns"
  domain = var.domain
}

/* ─── Edge (Route 53 A-record + ACM + CloudFront) ─── */
module "edge" {
  source      = "./modules/edge"
  domain      = var.domain
  zone_id     = var.zone_id
  frontend_ip = module.compute.frontend_public_ip
  project     = var.project
  env         = var.env
}


# ── aws_key_pair.tf ──

resource "aws_key_pair" "ci" {
  key_name   = "ci-key"                          # must match the string you pass as var.key_name
  public_key = file("${path.module}/ci-key.pub") # path on your local machine / runner machine
}

/* ─── Outputs ─── */
output "cloudfront_url" {
  value = module.edge.cf_domain_name
}


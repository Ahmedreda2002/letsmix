########################################
#  EC2 Key pair (public half only)
########################################
resource "aws_key_pair" "ci" {
  key_name   = "ci-key"
  public_key = file("${path.module}/ci-key.pub")
}

########################################
#  Navidrome EC2 in Casablanca WLZ
########################################
resource "aws_instance" "music" {
  ami             = data.aws_ami.amazon_linux_2023.id
  instance_type   = "t3.medium"
  subnet_id       = module.network.public_subnet_ids[0]
  security_groups = [module.network.sg_id]
  key_name        = aws_key_pair.ci.key_name

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = 200 # music library
    volume_type = "gp3"
  }

  user_data = <<-EOS
    #!/bin/bash
    set -e
    yum -y update
    yum -y install unzip wget

    # Mount extra EBS for music
    mkfs -t xfs /dev/xvdb
    mkdir -p /music
    echo "/dev/xvdb /music xfs defaults,nofail 0 2" >> /etc/fstab
    mount -a

    # Download latest Navidrome binary
    ND_VERSION=$(curl -s https://api.github.com/repos/navidrome/navidrome/releases/latest |
                 grep '"tag_name":' | cut -d'"' -f4)
    wget -qO /tmp/navidrome.zip \
      "https://github.com/navidrome/navidrome/releases/download/${ND_VERSION}/navidrome_${ND_VERSION}_Linux_x86_64.zip"
    unzip -o /tmp/navidrome.zip -d /opt/navidrome

    # Create service account
    useradd --system --home /opt/navidrome --shell /sbin/nologin navidrome
    chown -R navidrome:navidrome /opt/navidrome /music

    # systemd unit
    cat >/etc/systemd/system/navidrome.service <<'UNIT'
    [Unit]
    Description=Navidrome Music Server
    After=network.target

    [Service]
    User=navidrome
    Group=navidrome
    WorkingDirectory=/opt/navidrome
    ExecStart=/opt/navidrome/navidrome --configfile=/opt/navidrome/navidrome.toml
    Restart=on-failure
    LimitNOFILE=65536

    [Install]
    WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now navidrome
  EOS
}

output "wlz_ip" {
  value = aws_instance.music.public_ip
}

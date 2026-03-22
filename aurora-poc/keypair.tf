resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "aurora-poc-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

# ローカルに秘密鍵を保存
resource "local_file" "private_key" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "${path.module}/aurora-poc-bastion.pem"
  file_permission = "0600"
}

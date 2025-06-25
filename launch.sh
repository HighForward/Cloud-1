ansible-vault decrypt --output=ec2-perm.pem ec2-perm-encrypted.pem
chmod 600 ec2-perm.pem

terraform apply

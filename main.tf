# Fetch the existing security group (if it exists)
data "aws_security_group" "existing_prometheus_grafana_sg" {
  filter {
    name   = "group-name"
    values = ["prometheus_grafana_sg"]
  }

  filter {
    name   = "vpc-id"
    values = ["vpc-0d58c2b1c9009ac23"] # Replace with your actual VPC ID
  }
}

# Conditionally create a new security group if the existing one is not found
resource "aws_security_group" "prometheus_grafana_sg" {
  count       = length(data.aws_security_group.existing_prometheus_grafana_sg.id) == 0 ? 1 : 0
  name        = "prometheus_grafana_sg"
  description = "Allow Prometheus and Grafana traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open SSH access to all IPs

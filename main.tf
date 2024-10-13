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

# Destroy the existing security group if it exists
resource "aws_security_group" "delete_existing_sg" {
  count = length(data.aws_security_group.existing_prometheus_grafana_sg.id) > 0 ? 1 : 0

  lifecycle {
    prevent_destroy = false
  }

  name = data.aws_security_group.existing_prometheus_grafana_sg.name

  # This block ensures that Terraform will destroy this resource if it exists.
}

# Create a new security group for Prometheus and Grafana
resource "aws_security_group" "prometheus_grafana_sg" {
  depends_on = [aws_security_group.delete_existing_sg] # Ensure deletion happens first

  name        = "prometheus_grafana_sg"
  description = "Allow Prometheus and Grafana traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open SSH access to all IPs
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open Prometheus port
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open Grafana port
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "PrometheusGrafanaSG"
  }
}

# Define the EC2 instance and attach the recreated security group
resource "aws_instance" "prometheus_grafana" {
  ami           = "ami-12345678"  # Replace with the correct AMI ID
  instance_type = "t2.micro"
  key_name      = "your-ssh-key"

  # Attach the recreated security group
  vpc_security_group_ids = [aws_security_group.prometheus_grafana_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user

    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Create Prometheus and Grafana containers
    mkdir /home/ec2-user/monitoring
    cd /home/ec2-user/monitoring

    # Docker Compose YAML for Prometheus and Grafana
    cat <<EOL > docker-compose.yml
    version: '3'

    services:
      prometheus:
        image: prom/prometheus
        container_name: prometheus
        ports:
          - "9090:9090"
        volumes:
          - ./prometheus.yml:/etc/prometheus/prometheus.yml

      grafana:
        image: grafana/grafana
        container_name: grafana
        ports:
          - "3000:3000"
    EOL

    # Prometheus configuration
    cat <<EOL > prometheus.yml
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:9090"]
    EOL

    # Start Docker containers
    sudo docker-compose up -d
  EOF

  tags = {
    Name = "Prometheus-Grafana"
  }
}

resource "aws_instance" "prometheus_grafana" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = "your-ssh-key"          # Your SSH key to access the EC2 instance

  tags = {
    Name = "PrometheusGrafanaServer"
  }

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
    cat << EOF > docker-compose.yml
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
    EOF

    # Prometheus configuration
    cat << EOF > prometheus.yml
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
    EOF

    # Start Docker containers
    sudo docker-compose up -d
  EOF
}

resource "aws_security_group" "prometheus_grafana_sg" {
  name        = "prometheus_grafana_sg"
  description = "Allow Prometheus and Grafana traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrometheusGrafanaSG"
  }
}

resource "aws_instance" "prometheus_grafana" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "your-ssh-key"

  vpc_security_group_ids = [aws_security_group.prometheus_grafana_sg.id]

  tags = {
    Name = "Prometheus-Grafana"
  }
}

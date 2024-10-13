resource "aws_instance" "prometheus_grafana" {
  ami           = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  key_name      = "Ramprakash-Amazon3"

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

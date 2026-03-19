resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "this" {
  name   = "${var.project_name}-db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.project_name}-params"
  family = var.use_aurora ? "aurora-mysql8.0" : "mysql8.0"

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }
}

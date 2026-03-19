resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier      = "${var.project_name}-aurora"
  engine                  = "aurora-mysql"
  engine_version          = var.engine_version
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]
  skip_final_snapshot     = true
}

resource "aws_rds_cluster_instance" "writer" {
  count              = var.use_aurora ? 1 : 0
  identifier         = "${var.project_name}-aurora-writer"
  cluster_identifier = aws_rds_cluster.this[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this[0].engine
}

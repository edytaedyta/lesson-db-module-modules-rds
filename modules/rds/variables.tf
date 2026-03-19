variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "use_aurora" {
  type        = bool
  description = "Whether to use Aurora cluster"
  default     = false
}

variable "engine" {
  type        = string
  description = "Database engine (mysql or aurora-mysql)"
  default     = "mysql"
}

variable "engine_version" {
  type        = string
  description = "Database engine version"
  default     = "8.0"
}

variable "instance_class" {
  type        = string
  description = "DB instance class"
  default     = "db.t3.micro"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ (RDS only)"
  default     = false
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

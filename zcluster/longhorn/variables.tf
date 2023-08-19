variable "domain" {
  description = "value of the domain"
  default     = "k3s.zhome.local"
}

variable "data_path" {
  description = "value of the data path"
  default     = "/storage"
}

variable "namespace" {
  type        = string
  description = "value of the namespace"
  default     = "longhorn-system"
}

variable "cifs_backup_user" {
  description = "value of the cifs backup user"
  default     = "backup"
}

variable "cifs_backup_password" {
  description = "value of the cifs backup password"
  default     = "backup"
}

variable "cifs_backup_target" {
  description = "value of the cifs backup server"
}


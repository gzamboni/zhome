variable "postgresql_config" {
  description = "values to pass to the postgresql chart"
  type = object({
    enabled = bool
    auth = object({
      postgresPassword = string
    })
  })
  default = {
    enabled = false
    auth = {
      postgresPassword = ""
    }
  }
}

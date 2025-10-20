
variable "fixed_ip" {
  description = "The fixed IP address to assign to the DNS server."
  type        = string
}

variable "local_domain" {
  description = "The local domain name."
  type        = string
}

variable "router_ip" {
  description = "The IP address of the router to forward local queries to."
  type        = string
}

variable "adblock_ip" {
  description = "The IP address of the adblock server."
  type        = string
}

variable "local_network_cidr" {
  description = "The CIDR of the local network for reverse DNS."
  type        = string
}

variable "rndc_key_name" {
  description = "The name of the RNDC key used for DNS updates."
  type        = string
}


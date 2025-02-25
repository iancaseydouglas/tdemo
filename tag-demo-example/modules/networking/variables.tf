variable "address_space" {
  type = string
  description = "VNet address space"
}
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = ../modules/networking/variables.tf
}

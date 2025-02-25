variable "account_tier" {
  type = string
  description = "Storage account tier"
}
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = ../modules/storage/variables.tf
}

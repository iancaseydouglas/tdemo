variable "vm_size" {
  type = string
  description = "Size of the VM"
}
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = ../modules/compute/variables.tf
}

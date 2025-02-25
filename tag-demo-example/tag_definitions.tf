variable "tag_values" {
  description = "Values for required tags"
  type = object({
    app_name = string
    domain = string
    environment = string
    topology = string
    purpose = string
    cost_center = string
    system_owner = string
    business_owner = string
    data_classification = string
    resiliency_tier = string
  })

  validation {
    condition = can(regex(".+", var.tag_values.app_name))
    error_message = "app_name must not be empty"
  }

  validation {
    condition = can(regex("^(prod|preprod|int|dev)$", var.tag_values.domain))
    error_message = "domain must be one of: prod, preprod, int, dev"
  }

  validation {
    condition = can(regex("^(hub|island|spoke)$", var.tag_values.topology))
    error_message = "topology must be one of: hub, island, spoke"
  }

  validation {
    condition = can(regex("^(IT|BUS)$", var.tag_values.purpose))
    error_message = "purpose must be one of: IT, BUS"
  }

  validation {
    condition = can(regex("^CC[0-9]{3}$", var.tag_values.cost_center))
    error_message = "cost_center must be in format CC### (e.g., CC042)"
  }

  validation {
    condition = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.tag_values.system_owner))
    error_message = "system_owner must be a valid email"
  }

  validation {
    condition = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.tag_values.business_owner))
    error_message = "business_owner must be a valid email"
  }

  validation {
    condition = can(regex("^(Restricted|Confidential|Proprietary|Public|General)$", var.tag_values.data_classification))
    error_message = "data_classification must be one of: Restricted, Confidential, Proprietary, Public, General"
  }

  validation {
    condition = can(regex("^(Platinum|Gold|Silver|Bronze|Stone)$", var.tag_values.resiliency_tier))
    error_message = "resiliency_tier must be one of: Platinum, Gold, Silver, Bronze, Stone"
  }
}

variable "tags" {
  description = "Optional custom tags"
  type        = map(string)
  default     = {}
}

locals {
  required_tags = {
    AppName             = var.tag_values.app_name
    Domain              = var.tag_values.domain
    Environment         = var.tag_values.environment
    Topology            = var.tag_values.topology
    Purpose             = var.tag_values.purpose
    CostCenter          = var.tag_values.cost_center
    SystemOwner         = var.tag_values.system_owner
    BusinessOwner       = var.tag_values.business_owner
    DataClassification  = var.tag_values.data_classification
    ResiliencyTier      = var.tag_values.resiliency_tier
  }

  tags = merge(local.required_tags, var.tags)
}

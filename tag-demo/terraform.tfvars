tag_values = {
  app_name            = "DemoApp"
  domain              = "dev"
  environment         = "development"
  topology            = "spoke"
  purpose             = "IT"
  cost_center         = "CC042"
  system_owner        = "devops@company.com"
  business_owner      = "team@company.com"
  data_classification = "Public"
  resiliency_tier     = "Bronze"
}

tags = {
  "CreatedBy" = "Terraform"
  "Project"   = "TagDemo"
}

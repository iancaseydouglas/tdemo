# Azure Tag Demo Environment

This is a demonstration environment for implementing Azure resource tagging.

## Structure
- `tag_definitions.tf` - Tag variable definitions and locals
- `main.tf` - Root module with module calls
- `terraform.tfvars` - Sample tag values
- `modules/` - Sample modules with Azure resources
- `scripts/` - Tag implementation scripts

## Usage

1. Test regex patterns:
```
cd scripts
./test_tag_regex.sh
```

2. Add tag variable to modules:
```
cd scripts
./inject_module_vars.sh
```

3. Add tag parameter to module calls:
```
cd scripts
./inject_module_calls.sh
```

4. Add tags to resources:
```
cd scripts
./inject_resource_tags.sh
```

5. Verify changes with:
```
terraform fmt
terraform validate
terraform plan
```

After running the scripts, every Azure resource should have the tags parameter,
every module call should pass the tags, and every module should accept tags.

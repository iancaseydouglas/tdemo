#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Creating Azure Tag Demo Environment${NC}"

# Create base directory structure
echo "Creating directory structure..."
mkdir -p tag-demo/modules/{networking,compute,storage} tag-demo/scripts

# Create the scripts
echo "Creating scripts..."

# Script 1: Tag regex test
cat > tag-demo/scripts/test_tag_regex.sh << 'EOF'
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test function
test_regex() {
    local name=$1
    local pattern=$2
    local value=$3
    local expected=$4
    
    if [[ "$value" =~ $pattern ]]; then
        actual=0  # Success
    else
        actual=1  # Fail
    fi
    
    if [ "$actual" -eq "$expected" ]; then
        echo -e "${GREEN}✓${NC} $name: '$value' $([ $expected -eq 0 ] && echo 'matched' || echo 'rejected') as expected"
        return 0
    else
        echo -e "${RED}✗${NC} $name: '$value' $([ $actual -eq 0 ] && echo 'matched' || echo 'rejected') but expected $([ $expected -eq 0 ] && echo 'match' || echo 'rejection')"
        return 1
    fi
}

# Keep track of failures
failures=0

run_test() {
    if ! test_regex "$1" "$2" "$3" "$4"; then
        failures=$((failures+1))
    fi
}

# Test cases
echo "=== Testing app_name ==="
run_test "app_name empty" ".+" "" 1
run_test "app_name valid" ".+" "MyApp" 0

echo -e "\n=== Testing domain ==="
run_test "domain valid prod" "^(prod|preprod|int|dev)$" "prod" 0
run_test "domain valid dev" "^(prod|preprod|int|dev)$" "dev" 0
run_test "domain invalid" "^(prod|preprod|int|dev)$" "test" 1
run_test "domain empty" "^(prod|preprod|int|dev)$" "" 1

echo -e "\n=== Testing topology ==="
run_test "topology valid hub" "^(hub|island|spoke)$" "hub" 0
run_test "topology valid spoke" "^(hub|island|spoke)$" "spoke" 0
run_test "topology invalid" "^(hub|island|spoke)$" "network" 1

echo -e "\n=== Testing purpose ==="
run_test "purpose valid IT" "^(IT|BUS)$" "IT" 0
run_test "purpose valid BUS" "^(IT|BUS)$" "BUS" 0
run_test "purpose invalid" "^(IT|BUS)$" "DEV" 1
run_test "purpose lowercase" "^(IT|BUS)$" "it" 1

echo -e "\n=== Testing cost_center ==="
run_test "cost_center valid" "^CC[0-9]{3}$" "CC042" 0
run_test "cost_center invalid format" "^CC[0-9]{3}$" "CC1234" 1
run_test "cost_center no prefix" "^CC[0-9]{3}$" "123" 1
run_test "cost_center lowercase" "^CC[0-9]{3}$" "cc123" 1

echo -e "\n=== Testing email fields ==="
email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
run_test "email valid" "$email_regex" "user@company.com" 0
run_test "email no domain" "$email_regex" "user@" 1
run_test "email invalid chars" "$email_regex" "user#@company.com" 1
run_test "email no @" "$email_regex" "usercompany.com" 1

echo -e "\n=== Testing data_classification ==="
run_test "classification valid Restricted" "^(Restricted|Confidential|Proprietary|Public|General)$" "Restricted" 0
run_test "classification valid Public" "^(Restricted|Confidential|Proprietary|Public|General)$" "Public" 0
run_test "classification invalid" "^(Restricted|Confidential|Proprietary|Public|General)$" "Private" 1
run_test "classification lowercase" "^(Restricted|Confidential|Proprietary|Public|General)$" "public" 1

echo -e "\n=== Testing resiliency_tier ==="
run_test "tier valid Platinum" "^(Platinum|Gold|Silver|Bronze|Stone)$" "Platinum" 0
run_test "tier valid Bronze" "^(Platinum|Gold|Silver|Bronze|Stone)$" "Bronze" 0
run_test "tier invalid" "^(Platinum|Gold|Silver|Bronze|Stone)$" "Iron" 1
run_test "tier lowercase" "^(Platinum|Gold|Silver|Bronze|Stone)$" "gold" 1

# Summary
echo -e "\n=== Test Summary ==="
if [ $failures -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$failures test(s) failed!${NC}"
    exit 1
fi
EOF

# Script 2: Module var injection
cat > tag-demo/scripts/inject_module_vars.sh << 'EOF'
#!/bin/bash
find ../modules -name "variables.tf" -type f -exec sed -i '$ a\
variable "tags" {\
  description = "Resource tags"\
  type        = map(string)\
  default     = {}\
}' {} \;
echo "Tag variables added to modules"
EOF

# Script 3: Module call injection
cat > tag-demo/scripts/inject_module_calls.sh << 'EOF'
#!/bin/bash
find .. -name "*.tf" -type f -exec sed -i '/^module/,/^}/{/tags.*=.*}/!{/^}/i\  tags = local.tags
}' {} \;
echo "Tags parameter added to module calls"
EOF

# Script 4: Resource tag injection
cat > tag-demo/scripts/inject_resource_tags.sh << 'EOF'
#!/bin/bash
find ../modules -name "*.tf" -type f -exec sed -i '/^resource "azurerm_.*" .*{/,/^}/{/tags.*=.*}/!{/^}/i\  tags = var.tags
}' {} \;
echo "Tags added to Azure resources"
EOF

# Make scripts executable
chmod +x tag-demo/scripts/*.sh

# Create tag definitions file
echo "Creating tag definitions file..."
cat > tag-demo/tag_definitions.tf << 'EOF'
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
EOF

# Create main.tf
echo "Creating main.tf..."
cat > tag-demo/main.tf << 'EOF'
provider "azurerm" {
  features {}
}

module "networking" {
  source = "./modules/networking"
  address_space = "10.0.0.0/16"
}

module "compute" {
  source = "./modules/compute"
  vm_size = "Standard_B2s"
}

module "storage" {
  source = "./modules/storage"
  account_tier = "Standard"
}
EOF

# Create terraform.tfvars
echo "Creating terraform.tfvars..."
cat > tag-demo/terraform.tfvars << 'EOF'
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
EOF

# Create modules
echo "Creating module files..."

# Networking module
cat > tag-demo/modules/networking/variables.tf << 'EOF'
variable "address_space" {
  type = string
  description = "VNet address space"
}
EOF

cat > tag-demo/modules/networking/main.tf << 'EOF'
resource "azurerm_resource_group" "networking" {
  name     = "networking-rg"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "main-vnet"
  address_space       = [var.address_space]
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
}
EOF

# Compute module
cat > tag-demo/modules/compute/variables.tf << 'EOF'
variable "vm_size" {
  type = string
  description = "Size of the VM"
}
EOF

cat > tag-demo/modules/compute/main.tf << 'EOF'
resource "azurerm_resource_group" "compute" {
  name     = "compute-rg"
  location = "eastus"
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.compute.name
  location            = azurerm_resource_group.compute.location
  size                = var.vm_size
  admin_username      = "adminuser"
  network_interface_ids = ["dummy-id"]

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa DUMMY-KEY-FOR-DEMO"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
EOF

# Storage module
cat > tag-demo/modules/storage/variables.tf << 'EOF'
variable "account_tier" {
  type = string
  description = "Storage account tier"
}
EOF

cat > tag-demo/modules/storage/main.tf << 'EOF'
resource "azurerm_resource_group" "storage" {
  name     = "storage-rg"
  location = "eastus"
}

resource "azurerm_storage_account" "example" {
  name                     = "demostorageaccount"
  resource_group_name      = azurerm_resource_group.storage.name
  location                 = azurerm_resource_group.storage.location
  account_tier             = var.account_tier
  account_replication_type = "LRS"
}
EOF

# Create README
cat > tag-demo/README.md << 'EOF'
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
EOF

echo -e "${GREEN}Demo environment created successfully in ./tag-demo${NC}"
echo "To get started:"
echo "  cd tag-demo"
echo "  cd scripts"
echo "  ./test_tag_regex.sh"

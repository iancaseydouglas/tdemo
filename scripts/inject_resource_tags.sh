#!/bin/bash
# Adds tags to Azure resources with exclusions for resources that don't support tagging

# Default values
TARGET_DIR="."

# Resources that don't support tagging (add more as needed)
SKIP_RESOURCES=(
  "azurerm_subnet"
  "azurerm_virtual_network_peering"
  "azurerm_route"
  "azurerm_network_security_rule"
  "azurerm_role_assignment"
  "azurerm_policy_assignment"
  "azurerm_monitor_diagnostic_setting"
  "azurerm_private_endpoint_connection"
  "azurerm_log_analytics_solution"
  "azurerm_route_table_association"
  "azurerm_subnet_network_security_group_association"
  "azurerm_subnet_route_table_association"
  "azurerm_proximity_placement_group"
  "azurerm_management_lock"
  "azurerm_virtual_machine_extension"
)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--directory)
      TARGET_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -d, --directory DIR    Base directory to search from (default: current directory)"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Looking for Terraform files in: $TARGET_DIR"

# Process each file individually
find "$TARGET_DIR" -type f -name "*.tf" | while read -r file; do
  echo "Processing $file"
  
  # Create a temporary file
  temp_file=$(mktemp)
  
  # Process the file with awk
  awk -v skip_list="${SKIP_RESOURCES[*]}" '
    # Track resource blocks and nesting levels
    BEGIN { 
      in_resource = 0
      resource_level = 0
      has_tags = 0
      any_changes = 0
      current_resource = ""
      split(skip_list, skip_array, " ")
    }
    
    # Function to check if resource should be skipped
    function should_skip(resource) {
      for (i in skip_array) {
        if (resource == skip_array[i]) {
          return 1
        }
      }
      return 0
    }
    
    # Detect start of an Azure resource
    /resource[ \t]+"azurerm_/ { 
      in_resource = 1
      resource_level = 1
      has_tags = 0
      
      # Extract resource type
      match($0, /resource[ \t]+"([^"]+)"/, arr)
      current_resource = arr[1]
      
      print $0
      next
    }
    
    # Track opening braces
    /\{/ { 
      if (in_resource && resource_level > 0) {
        resource_level++
      }
      print $0
      next
    }
    
    # Check for existing tags
    /tags[ \t]*=/ {
      if (in_resource && resource_level == 2) {
        has_tags = 1
      }
      print $0
      next
    }
    
    # Track closing braces
    /\}/ { 
      if (in_resource && resource_level > 0) {
        resource_level--
        
        # If at the end of the resource block
        if (resource_level == 1) {
          # Add tags if needed and resource supports them
          if (!has_tags && !should_skip(current_resource)) {
            print "  tags = var.tags"
            any_changes = 1
          }
        }
      }
      print $0
      next
    }
    
    # Print all other lines
    { print $0 }
    
    # Signal if changes were made
    END { exit any_changes ? 1 : 0 }
  ' "$file" > "$temp_file"
  
  # Check if changes were made
  if [ $? -eq 1 ]; then
    mv "$temp_file" "$file"
    echo "  Tags added to resources"
  else
    rm "$temp_file"
    echo "  No changes needed"
  fi
done

echo "Tags added only to resources that support tagging"
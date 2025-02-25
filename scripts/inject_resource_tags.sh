#!/bin/bash
# Adds tags to Azure resources with simplified resource detection

# Default values
TARGET_DIR="."

# Resources that don't support tagging
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
      
      # Build an array of resources to skip
      num_skip = split(skip_list, skip_array, " ")
      for (i = 1; i <= num_skip; i++) {
        skip_map[skip_array[i]] = 1
      }
    }
    
    # Simple function to check if a resource should be skipped
    function is_skipped(res) {
      return (res in skip_map)
    }
    
    # Detect resource lines - simplified approach
    /^[ \t]*resource[ \t]+"azurerm_/ { 
      # Extract the resource type - everything between "azurerm_ and the next "
      start_pos = index($0, "azurerm_")
      temp = substr($0, start_pos)
      end_pos = index(temp, "\"")
      
      if (start_pos > 0 && end_pos > 0) {
        resource_type = substr($0, start_pos, end_pos - 1)
        in_resource = 1
        resource_level = 0
        has_tags = 0
        current_resource = resource_type
      }
      
      print $0
      next
    }
    
    # Track opening braces
    /\{/ { 
      if (in_resource) {
        resource_level++
      }
      print $0
      next
    }
    
    # Check for existing tags
    /tags[ \t]*=/ {
      if (in_resource) {
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
        if (resource_level == 0) {
          # Add tags if needed AND resource type is not in skip list
          if (!has_tags && !is_skipped(current_resource)) {
            print "  tags = var.tags"
            any_changes = 1
          }
          
          # Reset for next resource
          in_resource = 0
          current_resource = ""
          has_tags = 0
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

echo "Tags added to supported Azure resources"
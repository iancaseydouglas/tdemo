#!/bin/bash
# Adds tags to Azure resources with support for nested resources

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
    # Track resource blocks and state
    BEGIN { 
      global_level = 0
      any_changes = 0
      
      # Build an array of resources to skip
      num_skip = split(skip_list, skip_array, " ")
      for (i = 1; i <= num_skip; i++) {
        skip_map[skip_array[i]] = 1
      }
      
      # Maximum number of nested resources we can track
      max_resources = 50
      
      # Initialize tracking arrays
      for (i = 0; i < max_resources; i++) {
        resource_type[i] = ""
        has_tags[i] = 0
        is_resource[i] = 0
        resource_start_level[i] = 0
      }
      
      # Current resource index
      current_idx = 0
    }
    
    # Simple function to check if a resource should be skipped
    function is_skipped(res) {
      return (res in skip_map)
    }
    
    # Detect resource lines - look for any resource declaration at any level
    /resource[ \t]+"azurerm_/ { 
      # Extract the resource type
      start_pos = index($0, "azurerm_")
      temp = substr($0, start_pos)
      end_pos = index(temp, "\"")
      
      if (start_pos > 0 && end_pos > 0) {
        # Get the resource type
        res_type = substr(temp, 1, end_pos - 1)
        
        # Track this resource
        is_resource[current_idx] = 1
        resource_type[current_idx] = res_type
        has_tags[current_idx] = 0
        resource_start_level = global_level
        
        # Increment the index for next resource
        current_idx++
        if (current_idx >= max_resources) current_idx = 0  # Wrap around if needed
      }
      
      print $0
      next
    }
    
    # Track opening braces to maintain nesting level
    /\{/ { 
      global_level++
      print $0
      next
    }
    
    # Check for existing tags at any level
    /tags[ \t]*=/ {
      # Check if this tag belongs to any tracked resource
      for (i = 0; i < current_idx; i++) {
        if (is_resource[i]) {
          has_tags[i] = 1
        }
      }
      print $0
      next
    }
    
    # Track closing braces
    /\}/ { 
      global_level--
      
      # Check if any resource is ending at this level
      for (i = 0; i < current_idx; i++) {
        if (is_resource[i] && global_level == resource_start_level[i]) {
          # This resource block is ending
          
          # Add tags if needed AND resource type is not in skip list
          if (!has_tags[i] && !is_skipped(resource_type[i])) {
            print "  tags = var.tags"
            any_changes = 1
          }
          
          # Mark this resource as processed
          is_resource[i] = 0
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
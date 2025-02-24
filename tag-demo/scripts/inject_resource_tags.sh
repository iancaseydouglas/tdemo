#!/bin/bash
# This script adds tags specifically to top-level Azure resources, not to nested blocks

# Process each file individually for better control
for file in $(find ../modules -name "*.tf" -type f); do
  echo "Processing $file"
  # Create a temporary file
  temp_file=$(mktemp)
  
  # Process the file with awk for precise control
  awk '
    # Track resource blocks and nesting levels
    BEGIN { in_resource = 0; resource_level = 0; has_tags = 0; }
    
    # Detect start of an Azure resource (only at the top level)
    /^resource "azurerm_/ { 
      in_resource = 1
      resource_level = 1
      has_tags = 0
      print
      next
    }
    
    # Track opening braces to manage nesting
    /\{/ { 
      if (in_resource && resource_level > 0) {
        resource_level++
      }
      print
      next
    }
    
    # Check for existing tags at the resource level (level 1)
    /tags[ \t]*=/ {
      if (in_resource && resource_level == 1) {
        has_tags = 1
      }
      print
      next
    }
    
    # Track closing braces to manage nesting
    /\}/ { 
      if (in_resource && resource_level > 0) {
        resource_level--
        
        # If returning to level 0, we are at the end of the resource
        if (resource_level == 0) {
          # Add tags if not already present and this is the end of a resource
          if (!has_tags) {
            print "  tags = var.tags"
          }
          in_resource = 0
        }
      }
      print
      next
    }
    
    # Print all other lines
    { print }
  ' "$file" > "$temp_file"
  
  # Replace the original file
  mv "$temp_file" "$file"
done

echo "Tags added to top-level Azure resources only"
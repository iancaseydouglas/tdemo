#!/bin/bash
# Adds tags to Azure resources while leaving untouched files unmodified

# Default values
TARGET_DIR="."

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
  # Skip files that aren't in a modules directory
  if [[ "$file" != *"/modules/"* ]]; then
    continue
  fi
  
  # Skip files that don't contain Azure resources (optimization)
  if ! grep -q "^resource \"azurerm_" "$file"; then
    continue
  fi
  
  echo "Processing $file"
  
  # Create a temporary file
  temp_file=$(mktemp)
  
  # Flag to track if any actual changes were made
  changes_made=0
  
  # Process the file with awk for precise control
  awk '
    # Track resource blocks and nesting levels
    BEGIN { in_resource = 0; resource_level = 0; has_tags = 0; any_changes = 0; }
    
    # Detect start of an Azure resource (only at the top level)
    /^resource "azurerm_/ { 
      in_resource = 1
      resource_level = 1
      has_tags = 0
      print $0
      next
    }
    
    # Track opening braces to manage nesting
    /\{/ { 
      if (in_resource && resource_level > 0) {
        resource_level++
      }
      print $0
      next
    }
    
    # Check for existing tags at the resource level (level 1)
    /tags[ \t]*=/ {
      if (in_resource && resource_level == 1) {
        has_tags = 1
      }
      print $0
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
            printf "  tags = var.tags\n"
            any_changes = 1
          }
          in_resource = 0
        }
      }
      print $0
      next
    }
    
    # Print all other lines
    { print $0 }
    
    # Signal if any changes were made
    END { exit any_changes ? 1 : 0 }
  ' "$file" > "$temp_file"
  
  # Check if any changes were made (using awk's exit code)
  if [ $? -eq 1 ]; then
    # Changes were made - replace the file
    mv "$temp_file" "$file"
    echo "  Tags added to resources"
    changes_made=1
  else
    # No changes - discard the temp file
    rm "$temp_file"
    echo "  No changes needed"
  fi
done

echo "Tags added only to resources that needed them"
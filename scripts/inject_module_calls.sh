#!/bin/bash
# Adds tags parameter to module calls with flexible directory support

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

echo "Looking for module calls in: $TARGET_DIR"

# Process each file individually
for file in $(find "$TARGET_DIR" -name "*.tf" -type f); do
  echo "Processing $file"
  # Create a temporary file
  temp_file=$(mktemp)
  
  # Process the file with awk for precise control
  awk '
    # Track module blocks and nesting levels
    BEGIN { in_module = 0; module_level = 0; has_tags = 0; }
    
    # Detect start of a module call (only at the top level)
    /^module "/ { 
      in_module = 1
      module_level = 1
      has_tags = 0
      print
      next
    }
    
    # Track opening braces to manage nesting
    /\{/ { 
      if (in_module && module_level > 0) {
        module_level++
      }
      print
      next
    }
    
    # Check for existing tags parameter
    /tags[ \t]*=/ {
      if (in_module && module_level == 1) {
        has_tags = 1
      }
      print
      next
    }
    
    # Track closing braces to manage nesting
    /\}/ { 
      if (in_module && module_level > 0) {
        module_level--
        
        # If returning to level 0, we are at the end of the module call
        if (module_level == 0) {
          # Add tags if not already present and this is the end of a module call
          if (!has_tags) {
            print "  tags = local.tags"
          }
          in_module = 0
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

echo "Tags parameter added to module calls"
#!/bin/bash
# Adds tags variable to module definitions without changing file formatting

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

echo "Looking for variables.tf files in: $TARGET_DIR"

# Process each variables.tf file in modules directories
find "$TARGET_DIR" -type f -name "variables.tf" | while read -r file; do
  # Skip files that aren't in a modules directory
  if [[ "$file" != *"/modules/"* ]]; then
    continue
  fi
  
  echo "Processing $file"
  
  # Check if tags variable already exists
  if grep -q "variable \"tags\"" "$file"; then
    echo "  Tags variable already exists, skipping"
    continue
  fi
  
  # Create a temporary file
  temp_file=$(mktemp)
  
  # Copy the original file to temporary file
  cp "$file" "$temp_file"
  
  # Append tags variable to the file
  cat >> "$temp_file" << 'EOF'
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
EOF

  # Replace the original file
  mv "$temp_file" "$file"
  echo "  Added tags variable"
done

echo "Tags variable added to module definitions"
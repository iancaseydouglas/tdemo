#!/bin/bash
find ../modules -name "variables.tf" -type f -exec sed -i '$ a\
variable "tags" {\
  description = "Resource tags"\
  type        = map(string)\
  default     = {}\
}' {} \;
echo "Tag variables added to modules"

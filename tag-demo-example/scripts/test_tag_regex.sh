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

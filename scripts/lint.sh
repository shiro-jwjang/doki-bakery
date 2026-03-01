#!/bin/bash
# Code Quality Script for Doki Bakery

set -e

echo "🎨 Running code quality checks..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Format GDScript files
echo -e "${YELLOW}📝 Formatting GDScript files...${NC}"
if gdformat scripts/; then
    echo -e "${GREEN}✅ GDScript files formatted${NC}"
else
    echo -e "${RED}❌ Formatting failed${NC}"
    exit 1
fi
echo ""

# 2. Run linter
echo -e "${YELLOW}🔍 Running linter...${NC}"
if gdlint scripts/; then
    echo -e "${GREEN}✅ No linter errors${NC}"
else
    echo -e "${YELLOW}⚠️  Linter warnings found (non-blocking)${NC}"
fi
echo ""

# 3. Validate JSON files
echo -e "${YELLOW}📋 Validating JSON files...${NC}"
json_valid=true
for file in data/*.json; do
    if [ -f "$file" ]; then
        if python3 -m json.tool "$file" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $file"
        else
            echo -e "  ${RED}✗${NC} $file"
            json_valid=false
        fi
    fi
done

if [ "$json_valid" = true ]; then
    echo -e "${GREEN}✅ All JSON files are valid${NC}"
else
    echo -e "${RED}❌ Invalid JSON files found${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}🎉 All checks passed!${NC}"

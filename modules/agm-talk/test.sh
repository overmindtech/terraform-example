#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Tests the Loom CDN session leak replication
#
# Requires: terraform outputs available (run terraform apply first)
# =============================================================================

CF_URL=$(terraform output -raw cloudfront_url)
LAMBDA_URL=$(terraform output -raw lambda_url)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "============================================"
echo " Loom CDN Session Leak — Replication Test"
echo "============================================"
echo ""
echo "CloudFront URL: ${CF_URL}"
echo "Lambda URL:     ${LAMBDA_URL}"
echo ""

# ---- Test 1: Direct Lambda (should be safe) ----
echo "${YELLOW}--- Test 1: Direct Lambda (baseline, no CloudFront) ---${NC}"
echo ""

echo "Sending request as User A (session=ALICE_SECRET)..."
LAMBDA_A=$(curl -s -D - -o /dev/null -H "Cookie: session=ALICE_SECRET" "${LAMBDA_URL}" 2>&1)
COOKIE_A=$(echo "$LAMBDA_A" | grep -i "set-cookie" | head -1 || true)
echo "  Response Set-Cookie: ${COOKIE_A:-<none>}"

echo "Sending request as User B (session=BOB_SECRET)..."
LAMBDA_B=$(curl -s -D - -o /dev/null -H "Cookie: session=BOB_SECRET" "${LAMBDA_URL}" 2>&1)
COOKIE_B=$(echo "$LAMBDA_B" | grep -i "set-cookie" | head -1 || true)
echo "  Response Set-Cookie: ${COOKIE_B:-<none>}"

if echo "$COOKIE_B" | grep -q "ALICE_SECRET"; then
  echo "${RED}  FAIL: Lambda is leaking cookies (this shouldn't happen)${NC}"
else
  echo "${GREEN}  PASS: Each user gets their own cookie back${NC}"
fi

echo ""

# ---- Test 2: Through CloudFront (should demonstrate the leak) ----
echo "${YELLOW}--- Test 2: Through CloudFront (testing the leak) ---${NC}"
echo ""

CACHE_BUSTER="/app-$(date +%s).js"

echo "Sending request as User A (session=ALICE_SECRET) to ${CF_URL}${CACHE_BUSTER}..."
CF_A=$(curl -s -D - -o /dev/null -H "Cookie: session=ALICE_SECRET" "${CF_URL}${CACHE_BUSTER}" 2>&1)
COOKIE_CF_A=$(echo "$CF_A" | grep -i "set-cookie" | head -1 || true)
CF_HIT_A=$(echo "$CF_A" | grep -i "x-cache" | head -1 || true)
echo "  X-Cache:    ${CF_HIT_A}"
echo "  Set-Cookie: ${COOKIE_CF_A:-<none>}"

echo "Sending request as User B (session=BOB_SECRET) within 1 second..."
CF_B=$(curl -s -D - -o /dev/null -H "Cookie: session=BOB_SECRET" "${CF_URL}${CACHE_BUSTER}" 2>&1)
COOKIE_CF_B=$(echo "$CF_B" | grep -i "set-cookie" | head -1 || true)
CF_HIT_B=$(echo "$CF_B" | grep -i "x-cache" | head -1 || true)
echo "  X-Cache:    ${CF_HIT_B}"
echo "  Set-Cookie: ${COOKIE_CF_B:-<none>}"

echo ""

if echo "$COOKIE_CF_B" | grep -q "ALICE_SECRET"; then
  echo "${RED}  SESSION LEAK CONFIRMED!${NC}"
  echo "${RED}  User B received User A's session cookie (ALICE_SECRET)${NC}"
  echo ""
  echo "  This is exactly what happened at Loom. The CDN cached the"
  echo "  Set-Cookie header from User A's response and served it to User B."
elif [ -z "$COOKIE_CF_B" ]; then
  echo "${GREEN}  No Set-Cookie in User B's response.${NC}"
  echo "  CloudFront may have stripped it. Try running the test again —"
  echo "  the behavior can be timing-dependent."
else
  echo "${YELLOW}  User B got a Set-Cookie but it contains their own token.${NC}"
  echo "  The cache may have expired between requests. Try again quickly."
fi

echo ""
echo "============================================"
echo ""
echo "What you're seeing:"
echo "  - The Lambda function simulates rolling sessions (extends cookie expiry)"
echo "  - The CloudFront cache policy has cookies_config = none (not in cache key)"
echo "  - The origin request policy forwards ALL cookies to the origin"
echo "  - CloudFront caches the Set-Cookie header and serves it to all users"
echo "  - This is the exact trap from migrating forwarded_values to cache policies"
echo ""

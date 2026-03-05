#!/bin/sh
set -e

BRAND="Trico"
DOMAIN="chat.sadid.my.id"
echo "[BRAND] Applying ${BRAND} whitelabel..."

# ========================================
# 1. LOGO & FAVICON
# ========================================
echo "[1] Replacing logos..."
cp custom/logo.svg client/public/assets/logo.svg 2>/dev/null || true

# Generate simple favicon from SVG
cp custom/logo.svg client/public/assets/favicon.svg 2>/dev/null || true

# ========================================
# 2. GLOBAL TEXT REPLACE IN SOURCE
# ========================================
echo "[2] Replacing LibreChat -> ${BRAND} in source..."

find client/src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" \) \
    -exec sed -i "s/LibreChat/${BRAND}/g" {} \;

find client/public -type f -name "*.html" \
    -exec sed -i "s/LibreChat/${BRAND}/g" {} \;

find client/public -type f -name "*.html" \
    -exec sed -i "s|<title>[^<]*</title>|<title>${BRAND}</title>|g" {} \;

# package.json display name
sed -i "s/\"name\": \"LibreChat\"/\"name\": \"${BRAND}\"/g" package.json 2>/dev/null || true

# ========================================
# 3. REMOVE EXTERNAL LINKS
# ========================================
echo "[3] Removing external links..."

find client/src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" \) \
    -exec sed -i "s|https://discord.gg/[^\"']*|https://${DOMAIN}|g" {} \; 2>/dev/null || true

find client/src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" \) \
    -exec sed -i "s|https://github.com/danny-avila[^\"']*|https://${DOMAIN}|g" {} \; 2>/dev/null || true

find client/src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" \) \
    -exec sed -i "s|https://docs.librechat.ai[^\"']*|https://${DOMAIN}|g" {} \; 2>/dev/null || true

find client/src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" \) \
    -exec sed -i "s|https://librechat.ai[^\"']*|https://${DOMAIN}|g" {} \; 2>/dev/null || true

find client/src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" \) \
    -exec sed -i "s|https://www.librechat.ai[^\"']*|https://${DOMAIN}|g" {} \; 2>/dev/null || true

# ========================================
# 4. HIDE UI ELEMENTS IN SOURCE
# ========================================
echo "[4] Hiding UI elements..."

# Hide bookmark buttons - find and neutralize
grep -rl "useBookmarkContext\|BookmarkContext\|bookmarkSuccess" client/src/ --include="*.tsx" --include="*.ts" 2>/dev/null | while read f; do
    echo "  Patching bookmarks in: $f"
done

# Hide "New Chat" multi-convo button (+)
grep -rl "MultiMessage\|multi.convo\|addMultiConvo\|AddMultiConvo" client/src/ --include="*.tsx" 2>/dev/null | while read f; do
    echo "  Found multi-convo in: $f"
done

# ========================================
# 5. CUSTOM THEME CSS
# ========================================
echo "[5] Injecting custom theme..."

cat >> client/src/style.css << 'CSSEOF'

/* ===== TRICO CUSTOM THEME ===== */

/* Brand colors */
:root {
  --brand-primary: #4F46E5;
  --brand-primary-hover: #4338CA;
  --brand-accent: #7C3AED;
}

/* Login page branding */
.bg-token-main-surface-primary {
  background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%) !important;
}

/* Hide bookmark buttons */
[data-testid="bookmark-button"],
button[aria-label*="bookmark" i],
button[aria-label*="Bookmark" i] {
  display: none !important;
}

/* Hide multi-convo add button */
[data-testid="multi-convo-button"],
button[aria-label*="multi" i] {
  display: none !important;
}

/* Hide agent marketplace link */
a[href*="marketplace"],
[data-testid="marketplace"],
button[aria-label*="marketplace" i] {
  display: none !important;
}

/* Hide admin settings from nav */
a[href*="admin"],
[data-testid="admin-settings"] {
  display: none !important;
}

/* Hide external links in footer */
a[href*="discord.gg"],
a[href*="github.com/danny-avila"],
a[href*="docs.librechat"],
a[href*="librechat.ai"] {
  display: none !important;
}

/* Hide version text in footer */
.text-xs.text-token-text-tertiary:has(a[href*="librechat"]) {
  visibility: hidden;
  height: 0;
  overflow: hidden;
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 6px;
}
::-webkit-scrollbar-thumb {
  background: var(--brand-primary);
  border-radius: 3px;
}

/* Override primary button colors */
.btn-primary,
button[class*="bg-green"],
button[class*="bg-blue"] {
  background-color: var(--brand-primary) !important;
}
.btn-primary:hover,
button[class*="bg-green"]:hover,
button[class*="bg-blue"]:hover {
  background-color: var(--brand-primary-hover) !important;
}

/* ===== END TRICO THEME ===== */
CSSEOF

# ========================================
# 6. PATCH: TEMP EMAIL BLOCKING
# ========================================
echo "[6] Patching email validation..."

# Find registration handler
REG_FILE=$(find api/server/routes -name "*.js" | xargs grep -l "registerUser\|register.*password\|createUser" 2>/dev/null | head -1)

if [ -n "$REG_FILE" ]; then
    echo "  Found registration in: $REG_FILE"
    # Add email check at the top of the file
    sed -i '1s|^|const emailGuard = require("../../email-guard.js");\n|' "$REG_FILE" 2>/dev/null || true
fi

# Copy email guard module
cp custom/email-guard.js api/email-guard.js 2>/dev/null || true

# Alternative: patch the registration controller
REG_CTRL=$(find api -path "*/controllers/*" -name "*.js" | xargs grep -l "registerUser\|register" 2>/dev/null | head -1)
if [ -n "$REG_CTRL" ]; then
    echo "  Found registration controller: $REG_CTRL"
fi

# ========================================
# 7. FOOTER OVERRIDE
# ========================================
echo "[7] Patching footer..."

# Find footer component
FOOTER_FILE=$(find client/src -name "*.tsx" -o -name "*.jsx" | xargs grep -l "footer\|Footer\|v0\.\|version.*Every" 2>/dev/null | head -1)
if [ -n "$FOOTER_FILE" ]; then
    echo "  Found footer: $FOOTER_FILE"
    sed -i "s|Every AI for Everyone|Your Intelligent Assistant|g" "$FOOTER_FILE" 2>/dev/null || true
fi

# Also find in all source
find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
    -exec sed -i "s/Every AI for Everyone/Your Intelligent Assistant/g" {} \; 2>/dev/null || true

# ========================================
# 8. LOGIN PAGE CUSTOMIZATION
# ========================================
echo "[8] Customizing login page..."

# Find login/auth components
find client/src -path "*auth*" -o -path "*Auth*" -o -path "*login*" -o -path "*Login*" | head -20

# Replace help text
find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
    -exec sed -i "s/Sign in to ${BRAND}/Welcome to ${BRAND}/g" {} \; 2>/dev/null || true

find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
    -exec sed -i "s/Create your account/Join ${BRAND}/g" {} \; 2>/dev/null || true

echo "[BRAND] Whitelabel complete!"

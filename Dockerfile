FROM node:20-alpine AS node

RUN apk add --no-cache jemalloc python3 py3-pip
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

ARG NODE_MAX_OLD_SPACE_SIZE=6144

RUN mkdir -p /app && chown node:node /app
WORKDIR /app

USER node

COPY --chown=node:node package.json package-lock.json ./
COPY --chown=node:node api/package.json ./api/package.json
COPY --chown=node:node client/package.json ./client/package.json
COPY --chown=node:node packages/data-provider/package.json ./packages/data-provider/package.json
COPY --chown=node:node packages/data-schemas/package.json ./packages/data-schemas/package.json
COPY --chown=node:node packages/api/package.json ./packages/api/package.json

RUN \
    touch .env ; \
    mkdir -p /app/client/public/images /app/logs /app/uploads ; \
    npm config set fetch-retry-maxtimeout 600000 ; \
    npm config set fetch-retries 5 ; \
    npm config set fetch-retry-mintimeout 15000 ; \
    npm ci --no-audit

COPY --chown=node:node . .

# Whitelabel text replacement
RUN find client/src -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" \) \
        -exec sed -i 's/LibreChat/Trico/g' {} + && \
    find client -maxdepth 1 -type f -name "*.html" \
        -exec sed -i 's/LibreChat/Trico/g' {} + && \
    find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
        -exec sed -i 's/Every AI for Everyone/Your Intelligent Assistant/g' {} + 2>/dev/null || true

# Replace external links
RUN find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
        -exec sed -i 's|https://librechat.ai|https://chat.sadid.my.id/tos|g' {} + 2>/dev/null || true && \
    find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
        -exec sed -i 's|https://www.librechat.ai|https://chat.sadid.my.id/tos|g' {} + 2>/dev/null || true && \
    find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
        -exec sed -i 's|https://docs.librechat.ai[^"]*|https://chat.sadid.my.id|g' {} + 2>/dev/null || true && \
    find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
        -exec sed -i 's|discord.gg/[^"]*|chat.sadid.my.id|g' {} + 2>/dev/null || true && \
    find client/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
        -exec sed -i 's|github.com/danny-avila/LibreChat|chat.sadid.my.id|g' {} + 2>/dev/null || true

# CSS overrides to hide UI elements (each line separate, no comments)
RUN echo '' >> client/src/style.css && \
    echo '[data-testid="bookmark-button"] { display: none !important; }' >> client/src/style.css && \
    echo 'button[aria-label*="bookmark" i] { display: none !important; }' >> client/src/style.css && \
    echo '[data-testid="multi-convo-button"] { display: none !important; }' >> client/src/style.css && \
    echo '.multi-convo-button { display: none !important; }' >> client/src/style.css && \
    echo 'a[href*="marketplace"] { display: none !important; }' >> client/src/style.css && \
    echo 'a[href*="/admin"] { display: none !important; }' >> client/src/style.css && \
    echo 'nav a[href*="admin"] { display: none !important; }' >> client/src/style.css && \
    echo 'a[href*="discord.gg"] { display: none !important; }' >> client/src/style.css && \
    echo 'a[href*="github.com/danny-avila"] { display: none !important; }' >> client/src/style.css

# Build frontend with all changes baked in
RUN \
    NODE_OPTIONS="--max-old-space-size=${NODE_MAX_OLD_SPACE_SIZE}" npm run frontend ; \
    npm prune --production ; \
    npm cache clean --force

EXPOSE 3080
ENV HOST=0.0.0.0
CMD ["npm", "run", "backend"]

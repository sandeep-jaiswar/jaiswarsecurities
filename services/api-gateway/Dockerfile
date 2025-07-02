# ---- Base ----
FROM node:18-alpine AS base
WORKDIR /usr/src/app

COPY package.json package-lock.json lerna.json ./
RUN npm ci

COPY . .

# ---- Development ----
FROM base AS development
WORKDIR /usr/src/app

CMD ["npm", "run", "dev", "--workspace=api-gateway"]

# ---- Production ----
FROM base AS production
WORKDIR /usr/src/app

RUN npm run build --workspace=api-gateway

# Remove dev dependencies
RUN npm prune --production

CMD ["node", "services/api-gateway/index.js"]

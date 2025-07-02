# ---- Base ----
FROM node:18-alpine AS base
WORKDIR /usr/src/app

# Copy root dependency management files
COPY package.json package-lock.json lerna.json ./

# Install all dependencies
RUN npm ci

# Copy the rest of the monorepo
COPY . .

# ---- Dev ----
FROM base AS dev
WORKDIR /usr/src/app

EXPOSE 3001

CMD ["npm", "run", "dev", "--workspace=client"]

# ---- Prod ----
FROM base AS prod
WORKDIR /usr/src/app

# Build the client application
RUN npm run build --workspace=client

# The "next build" command creates a standalone folder with a production-ready server.
# We will now create a new, clean stage with only the standalone server.
FROM node:18-alpine AS runner

WORKDIR /usr/src/app

# Set production environment
ENV NODE_ENV=production

# Copy the standalone server from the prod stage
COPY --from=prod /usr/src/app/client/.next/standalone ./
# Copy the static assets
COPY --from=prod /usr/src/app/client/.next/static ./.next/static
# Copy the public assets
COPY --from=prod /usr/src/app/client/public ./public

EXPOSE 3001
ENV PORT 3001

# Start the server
CMD ["node", "server.js"]

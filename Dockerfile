# 👇 1
FROM node:24-alpine AS base

ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV

ARG PORT
ENV PORT=$PORT

ARG CORS_ORIGINS
ENV CORS_ORIGINS=$CORS_ORIGINS

ARG CORS_MAX_AGE
ENV CORS_MAX_AGE=$CORS_MAX_AGE

ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL

ARG AUTH_JWT_SECRET
ENV AUTH_JWT_SECRET=$AUTH_JWT_SECRET

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
# 👇 1.1
RUN apk add --no-cache libc6-compat

# 👇 1
FROM base AS dev-deps

WORKDIR /app

# 👇 2
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

# 👇 1
FROM base AS prod-deps

WORKDIR /app

# 👇 3
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

# 👇 1
FROM base AS builder
WORKDIR /app

# 👇 4
COPY --from=dev-deps /app/node_modules ./node_modules
COPY . .

RUN pnpm build

# 👇 1
FROM base AS runner

WORKDIR /app

# 👇 5
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/migrations ./dist/migrations

EXPOSE 3000

CMD ["node", "dist/src/main"]

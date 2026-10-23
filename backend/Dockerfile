FROM node:24.22.1-alpine

WORKDIR /app

# Install pnpm via corepack
RUN corepack enable && corepack prepare pnpm@12.15.0 --activate

COPY package*.json pnpm-lock.yaml* pnpm-workspace.yaml ./

RUN pnpm install --frozen-lockfile --prod

COPY src/ ./src/
COPY database/ ./database/

EXPOSE 4000

CMD ["node", "src/app.js"]

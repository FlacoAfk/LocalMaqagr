FROM node:20-alpine

WORKDIR /app

# Install pnpm via corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

COPY package*.json pnpm-lock.yaml* ./

RUN pnpm install --frozen-lockfile --prod

COPY src/ ./src/
COPY database/ ./database/

EXPOSE 4000

CMD ["node", "src/app.js"]

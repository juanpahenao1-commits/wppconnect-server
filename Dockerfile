FROM node:22.20.0-alpine AS base
WORKDIR /usr/src/wpp-server
ENV NODE_ENV=production PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
COPY package.json ./
RUN apk update && \
    apk add --no-cache \
    vips-dev \
    fftw-dev \
    gcc \
    g++ \
    make \
    libc6-compat \
    && rm -rf /var/cache/apk/*
RUN npm install --legacy-peer-deps && \
    npm install --os=linux --libc=musl --cpu=x64 sharp && \
    npm cache clean --force

FROM base AS build
WORKDIR /usr/src/wpp-server
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
COPY package.json  ./
RUN yarn install --production=false --pure-lockfile
RUN yarn cache clean
COPY . .
RUN yarn build

FROM base
WORKDIR /usr/src/wpp-server/
RUN apk add --no-cache chromium
RUN yarn cache clean
COPY . .
COPY --from=build /usr/src/wpp-server/ /usr/src/wpp-server/
EXPOSE 21465
ENTRYPOINT ["node", "dist/server.js"]

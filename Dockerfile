# Stage 1: Build Mattermost Server
FROM golang:1.22 AS server-builder

# Install required build dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /server

# Copy server source
COPY ./server/. .

# Build server binaries
RUN make build-linux

# Stage 2: Build Webapp
FROM node:18 AS webapp-builder

WORKDIR /webapp

# Copy webapp source
COPY ./webapp .

# Install dependencies and build
RUN npm ci
RUN npm run build

# Stage 3: Final Image
FROM mattermost/mattermost-team-edition:9.11.5

# Copy built artifacts
COPY --from=server-builder /server/dist/mattermost /mattermost/bin/
COPY --from=webapp-builder /webapp/dist /mattermost/client/

# Preserve original entrypoint and cmd
ENTRYPOINT ["/mattermost/bin/mattermost"]
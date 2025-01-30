# Stage 1: Build the server and webapp
FROM golang:1.20 AS builder

# Install Node.js (required for webapp)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Build Mattermost **Webapp** first
WORKDIR /mattermost-webapp
COPY mattermost-webapp/ .
RUN npm ci --no-optional --force && npm run build

# Build Mattermost **Server**
WORKDIR /go/src/github.com/mattermost/mattermost-server
COPY . .
RUN make build-linux  # Use the correct target for Linux builds

# Stage 2: Final image
FROM alpine:3.17
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /mattermost

# Copy server binary and webapp assets
COPY --from=builder /go/src/github.com/mattermost/mattermost-server/bin/mattermost /mattermost/bin/mattermost
COPY --from=builder /mattermost-webapp/dist /mattermost/client

EXPOSE 8065
ENTRYPOINT ["/mattermost/bin/mattermost"]
CMD ["server"]
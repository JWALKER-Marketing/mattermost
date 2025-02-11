# Stage 1: Build the server and webapp
FROM golang:1.22 AS builder 
# Устанавливаем системные зависимости
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    g++ \
    libpng-dev \
    make \
    nasm \
    git

# Устанавливаем Node.js 18.x
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Stage 1a: Собираем веб-приложение
WORKDIR /webapp
COPY ./webapp .

RUN npm install --force \
    imagemin-svgo@latest \
    svgo@latest \
    image-webpack-loader@latest \
    && npm ci --force \
    && npm run build

# Stage 1b: Собираем серверную часть
WORKDIR /go/src/github.com/mattermost/mattermost-server
COPY ./server .

# Исправляем версию Go в go.mod (если требуется)
RUN sed -i 's/go 1.22.0/go 1.22/' go.mod && \
    sed -i '/toolchain/d' go.mod  # Удаляем строку с toolchain

RUN make build-linux


# Stage 2: Финальный образ
FROM alpine:3.17

# Устанавливаем runtime-зависимости
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    libgcc \
    libstdc++

WORKDIR /mattermost

# Копируем собранные артефакты
COPY --from=builder /go/src/github.com/mattermost/mattermost-server/bin/mattermost /mattermost/bin/
COPY --from=builder /webapp/dist /mattermost/client/

# Настройки среды
EXPOSE 8065
ENTRYPOINT ["/mattermost/bin/mattermost"]
CMD ["server"]
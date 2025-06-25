# ========================================================
# Stage 1: Builder
# ========================================================
FROM golang:1.24-alpine AS builder
WORKDIR /app
ARG TARGETARCH

RUN apk --no-cache add build-base gcc wget unzip

COPY . .

ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"

RUN go build -ldflags "-w -s" -o build/x-ui main.go
RUN ./DockerInit.sh "$TARGETARCH"

# ========================================================
# Stage 2: Final Image with Nginx Reverse Proxy (Lightweight)
# ========================================================
FROM alpine:latest
ENV TZ=Asia/Tehran
WORKDIR /app

# نصب فقط پکیج‌های لازم و سبک
RUN apk update && apk add --no-cache \
    ca-certificates \
    tzdata \
    nginx \
    bash

COPY --from=builder /app/build/ /app/
COPY --from=builder /app/DockerEntrypoint.sh /app/
COPY --from=builder /app/x-ui.sh /usr/bin/x-ui

# کپی کانفیگ nginx (مطمئن شو فایل nginx.conf کنار Dockerfile هست)
COPY nginx.conf /etc/nginx/nginx.conf

RUN chmod +x \
    /app/DockerEntrypoint.sh \
    /app/x-ui \
    /usr/bin/x-ui

# اجرای همزمان nginx و 3x-ui
CMD ["/bin/sh", "-c", "nginx && /app/DockerEntrypoint.sh"]

ENTRYPOINT []

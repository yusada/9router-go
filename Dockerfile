# Build Stage
FROM golang:1.27-alpine AS builder

WORKDIR /app

# Install findutils agar bisa mencari file
RUN apk add --no-cache findutils

# Download dependencies
COPY go.mod go.sum* ./
RUN go mod download

# Copy source code
COPY . .

# SMART BUILD: Cari folder yang berisi main.go secara otomatis dan build
RUN MAIN_DIR=$(find . -name "main.go" -exec dirname {} \; | head -n 1) && \
    if [ -z "$MAIN_DIR" ]; then echo "Error: main.go tidak ditemukan di dalam repository!" && exit 1; fi && \
    echo "Ditemukan main.go di folder: $MAIN_DIR, memulai proses build..." && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/main $MAIN_DIR

# Run Stage
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Ambil hasil build binary dari stage sebelumnya
COPY --from=builder /app/main .

# Railway dynamic port
ENV PORT=8080
EXPOSE 8080

CMD ["./main"]

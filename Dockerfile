# Build Stage Frontend & Backend
FROM golang:1.27-alpine AS builder

WORKDIR /app

# Install Node.js, npm, dan findutils
RUN apk add --no-cache nodejs npm findutils

# Download dependencies Go terlebih dahulu
COPY go.mod go.sum* ./
RUN go mod download

# Copy seluruh source code
COPY . .

# SMART FRONTEND BUILD: Cek dan build frontend jika ada package.json
RUN if [ -f "package.json" ]; then         echo "Ditemukan package.json di root, menjalankan npm install & build..." &&         npm install && npm run build;     elif [ -f "web/package.json" ]; then         echo "Ditemukan package.json di folder web, mem-build frontend..." &&         cd web && npm install && npm run build && cd ..;     else         echo "Membuat folder dist dummy agar go:embed tidak error jika tidak ada frontend terpisah..." &&         mkdir -p web/dist;     fi

# SMART GO BUILD: Cari folder yang berisi main.go secara otomatis dan build
RUN MAIN_DIR=$(find . -name "main.go" -exec dirname {} \; | head -n 1) &&     if [ -z "$MAIN_DIR" ]; then echo "Error: main.go tidak ditemukan di dalam repository!" && exit 1; fi &&     echo "Ditemukan main.go di folder: $MAIN_DIR, memulai proses build Go..." &&     CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/main $MAIN_DIR

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

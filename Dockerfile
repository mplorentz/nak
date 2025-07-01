# Build stage
FROM golang:1.24-alpine AS builder

# Install git and ca-certificates (needed for fetching dependencies)
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
# Use CGO_ENABLED=0 to create a static binary
# Use -ldflags to strip debug info and reduce binary size
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o nak .

# Runtime stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests (needed for relay connections)
RUN apk --no-cache add ca-certificates

# Create a non-root user
RUN adduser -D -s /bin/sh nakuser

# Set working directory
WORKDIR /home/nakuser

# Copy the binary from builder stage
COPY --from=builder /app/nak /usr/local/bin/nak

# Make sure the binary is executable
RUN chmod +x /usr/local/bin/nak

# Switch to non-root user
USER nakuser

# Set the entrypoint
ENTRYPOINT ["nak"]

# Default command (show help)
CMD ["--help"] 
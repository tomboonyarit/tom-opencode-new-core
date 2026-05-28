# Next.js + Golang + PostgreSQL Docker Setup Guide

## Overview

This guide covers setting up a complete development environment using Docker for Next.js, Golang, and PostgreSQL.

## Docker Compose Configuration

### Complete Docker Compose File

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: project-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: projectdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/migrations:/docker-entrypoint-initdb.d
    networks:
      - project-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: project-backend
    environment:
      DATABASE_URL: postgres://postgres:postgres@postgres:5432/projectdb?sslmode=disable
      PORT: 8080
      JWT_SECRET: your-secret-key-change-in-production
      NODE_ENV: development
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - project-network
    volumes:
      - ./backend:/app
      - /app/node_modules
    command: sh -c "go run cmd/server/main.go"

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: project-frontend
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8080
      NEXT_PUBLIC_GRAPHQL_URL: http://localhost:8080/graphql
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - project-network
    volumes:
      - ./frontend:/app
      - /app/node_modules
    command: sh -c "npm run dev"

  redis:
    image: redis:7-alpine
    container_name: project-redis
    ports:
      - "6379:6379"
    networks:
      - project-network
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

networks:
  project-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
```

## Backend Docker Setup

### Dockerfile

```dockerfile
# backend/Dockerfile
# Stage 1: Build
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server cmd/server/main.go

# Stage 2: Runtime
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata

# Set timezone
ENV TZ=Asia/Bangkok

# Create non-root user
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# Set working directory
WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/server .

# Change ownership
RUN chown -R appuser:appuser /root/

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the application
CMD ["./server"]
```

### .dockerignore

```dockerfile
# backend/.dockerignore
.git
.gitignore
.env
.env.local
.env.*.local
node_modules
dist
build
*.log
coverage
test
tests
tmp
temp
```

## Frontend Docker Setup

### Dockerfile

```dockerfile
# frontend/Dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS deps

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci

# Stage 2: Builder
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# Set environment
ENV NEXT_TELEMETRY_DISABLED=1

# Build the application
RUN npm run build

# Stage 3: Runner
FROM node:18-alpine AS runner

WORKDIR /app

# Set environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup -g 1001 nodejs && \
    adduser -D -u 1001 -G nodejs nextjs

# Copy necessary files
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Change ownership
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000 || exit 1

# Start the application
CMD ["node", "server.js"]
```

### next.config.js (for standalone output)

```javascript
// frontend/next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['localhost'],
  },
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080',
  },
};

module.exports = nextConfig;
```

### .dockerignore

```dockerfile
# frontend/.dockerignore
.git
.gitignore
.env
.env.local
.env.*.local
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.next
out
build
dist
coverage
*.log
test
tests
tmp
temp
```

## Database Migrations

### Setup Migration Directory

```bash
# Create migration directory
mkdir -p backend/migrations

# Initialize migration (using golang-migrate)
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Create initial migration
migrate create -ext sql -dir backend/migrations -seq init_schema
```

### Migration Files

```sql
-- backend/migrations/000001_init_schema.up.sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Enable UUID extension for future use
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- backend/migrations/000001_init_schema.down.sql
DROP TABLE IF EXISTS order_items;
DROP TABLE IF NOT EXISTS orders;
DROP TABLE IF NOT EXISTS products;
DROP TABLE IF NOT EXISTS users;
```

## Development Workflow

### Starting the Development Environment

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Restart specific service
docker-compose restart backend
```

### Running Database Migrations

```bash
# Run migrations
docker-compose exec backend migrate -path /app/migrations -database "postgres://postgres:postgres@postgres:5432/projectdb?sslmode=disable" up

# Rollback migrations
docker-compose exec backend migrate -path /app/migrations -database "postgres://postgres:postgres@postgres:5432/projectdb?sslmode=disable" down

# Create new migration
docker-compose exec backend migrate create -ext sql -dir /app/migrations -seq add_new_table
```

### Accessing Services

```bash
# Access PostgreSQL
docker-compose exec postgres psql -U postgres -d projectdb

# Access Backend
docker-compose exec backend sh

# Access Frontend
docker-compose exec frontend sh
```

## Production Deployment

### Production Docker Compose

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: project-postgres-prod
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - project-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        - BUILDKIT_INLINE_CACHE=1
    container_name: project-backend-prod
    environment:
      DATABASE_URL: postgres://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}?sslmode=require
      PORT: 8080
      JWT_SECRET: ${JWT_SECRET}
      NODE_ENV: production
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - project-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - BUILDKIT_INLINE_CACHE=1
    container_name: project-frontend-prod
    environment:
      NEXT_PUBLIC_API_URL: ${API_URL}
      NEXT_PUBLIC_GRAPHQL_URL: ${GRAPHQL_URL}
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - project-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  project-network:
    driver: bridge

volumes:
  postgres_data:
```

### Production Environment Variables

```env
# .env.production
DB_USER=your_db_user
DB_PASSWORD=your_secure_password
DB_NAME=your_database_name
JWT_SECRET=your_very_secure_jwt_secret
API_URL=https://api.yourdomain.com
GRAPHQL_URL=https://api.yourdomain.com/graphql
```

### Build and Deploy

```bash
# Build production images
docker-compose -f docker-compose.prod.yml build

# Start production services
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop production services
docker-compose -f docker-compose.prod.yml down

# Update and restart
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d --build
```

## Monitoring and Maintenance

### Health Checks

```bash
# Check all services
docker-compose ps

# Check service health
docker inspect --format='{{.State.Health.Status}}' project-backend
docker inspect --format='{{.State.Health.Status}}' project-frontend
docker inspect --format='{{.State.Health.Status}}' project-postgres

# View service logs
docker-compose logs --tail=100 backend
docker-compose logs --tail=100 frontend
docker-compose logs --tail=100 postgres
```

### Database Backup

```bash
# Backup database
docker-compose exec postgres pg_dump -U postgres projectdb > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
docker-compose exec -T postgres psql -U postgres projectdb < backup_20240101_120000.sql
```

### Volume Management

```bash
# List volumes
docker volume ls

# Remove unused volumes
docker volume prune

# Backup volumes
docker run --rm -v project-postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz /data

# Restore volumes
docker run --rm -v project-postgres_data:/data -v $(pwd):/backup alpine tar xzf /backup/postgres_backup.tar.gz -C /
```

## Troubleshooting

### Common Issues

1. **Container won't start**
   ```bash
   # Check logs
   docker-compose logs backend

   # Check container status
   docker-compose ps

   # Rebuild container
   docker-compose up -d --build
   ```

2. **Database connection issues**
   ```bash
   # Check database is running
   docker-compose ps postgres

   # Test connection
   docker-compose exec postgres psql -U postgres -d projectdb -c "SELECT 1;"

   # Check database logs
   docker-compose logs postgres
   ```

3. **Port conflicts**
   ```bash
   # Check what's using the port
   netstat -tuln | grep 3000
   netstat -tuln | grep 8080
   netstat -tuln | grep 5432

   # Change port in docker-compose.yml
   ```

4. **Memory issues**
   ```bash
   # Check memory usage
   docker stats

   # Increase memory limits in docker-compose.yml
   ```

## Best Practices

1. Use separate compose files for development and production
2. Implement health checks for all services
3. Use environment variables for sensitive data
4. Implement proper logging
5. Use non-root users in containers
6. Implement proper volume management
7. Regular backups
8. Monitor resource usage
9. Use secrets management in production
10. Implement proper security practices

## Conclusion

This Docker setup provides a complete development and production environment for Next.js, Golang, and PostgreSQL. Follow these guidelines to ensure a robust and scalable deployment.
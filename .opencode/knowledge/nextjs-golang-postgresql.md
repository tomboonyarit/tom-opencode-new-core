# Next.js + Golang + PostgreSQL Project Development Guide

## Overview

This guide covers the development of full-stack applications using:
- **Frontend**: Next.js (React framework)
- **Backend**: Golang (server-side logic)
- **Database**: PostgreSQL (relational database)

## Technology Stack

### Next.js (Frontend)
- Modern React framework with server-side rendering
- App Router (Next.js 13+) for new architecture
- Server and Client Components
- API Routes for backend functionality
- TypeScript support

### Golang (Backend)
- High-performance server-side language
- Web frameworks: Gin, Echo, Fiber
- ORM libraries: GORM, Gorose, Zorm
- RESTful API development
- Concurrency support

### PostgreSQL (Database)
- Robust relational database
- Advanced features: JSON, full-text search, extensions
- ACID compliance
- Scalable and reliable

## Project Structure

```
project-root/
├── frontend/              # Next.js application
│   ├── app/              # App Router pages
│   ├── components/       # React components
│   ├── lib/              # Utilities
│   ├── public/           # Static assets
│   └── package.json
├── backend/              # Golang application
│   ├── cmd/              # Application entry points
│   ├── internal/         # Private application code
│   │   ├── handlers/     # HTTP handlers
│   │   ├── models/       # Data models
│   │   ├── repositories/ # Data access layer
│   │   └── services/     # Business logic
│   ├── pkg/              # Public libraries
│   ├── migrations/       # Database migrations
│   └── go.mod
└── docker-compose.yml    # Container orchestration
```

## Development Setup

### Prerequisites
- Node.js 18+ and npm/yarn/pnpm
- Go 1.21+
- PostgreSQL 14+
- Docker (optional, for containerized development)

### Frontend Setup (Next.js)

```bash
# Create Next.js project
npx create-next-app@latest frontend
cd frontend

# Install dependencies
npm install

# Development server
npm run dev
```

### Backend Setup (Golang)

```bash
# Create Go module
cd backend
go mod init github.com/yourusername/project

# Install dependencies
go get github.com/gin-gonic/gin
go get gorm.io/gorm
go get gorm.io/driver/postgres
go get github.com/lib/pq

# Development server
go run cmd/server/main.go
```

### Database Setup (PostgreSQL)

```bash
# Using Docker
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_DB=yourdatabase \
  -p 5432:5432 \
  postgres:16

# Or using local installation
createdb yourdatabase
```

## Architecture Patterns

### Backend Architecture

#### Layered Architecture
```
HTTP Request
    ↓
Handler (Controller)
    ↓
Service (Business Logic)
    ↓
Repository (Data Access)
    ↓
Database
```

#### Example: Gin Framework Setup

```go
package main

import (
    "github.com/gin-gonic/gin"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

type User struct {
    ID   uint   `json:"id" gorm:"primaryKey"`
    Name string `json:"name" gorm:"not null"`
    Email string `json:"email" gorm:"unique"`
}

var db *gorm.DB

func main() {
    // Connect to PostgreSQL
    dsn := "host=localhost user=postgres password=yourpassword dbname=yourdatabase port=5432 sslmode=disable"
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        panic("Failed to connect to database")
    }

    // Auto migrate
    db.AutoMigrate(&User{})

    // Setup Gin router
    r := gin.Default()

    // Routes
    r.GET("/users", getUsers)
    r.POST("/users", createUser)
    r.GET("/users/:id", getUser)
    r.PUT("/users/:id", updateUser)
    r.DELETE("/users/:id", deleteUser)

    r.Run(":8080")
}
```

### Frontend Integration

#### API Client Setup

```typescript
// frontend/lib/api.ts
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

export async function getUsers() {
    const response = await fetch(`${API_BASE_URL}/users`);
    return response.json();
}

export async function createUser(any) {
    const response = await fetch(`${API_BASE_URL}/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    return response.json();
}
```

#### Next.js API Routes (Alternative)

```typescript
// frontend/app/api/users/route.ts
import { NextResponse } from 'next/server';
import { getUsers as getBackendUsers } from '@/lib/api';

export async function GET() {
    try {
        const users = await getBackendUsers();
        return NextResponse.json(users);
    } catch (error) {
        return NextResponse.json(
            { error: 'Failed to fetch users' },
            { status: 500 }
        );
    }
}
```

## Database Operations

### GORM Examples

```go
package models

import "gorm.io/gorm"

type User struct {
    ID        uint      `json:"id" gorm:"primaryKey"`
    Name      string    `json:"name" gorm:"not null"`
    Email     string    `json:"email" gorm:"unique"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

// Repository Pattern
type UserRepository struct {
    db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
    return &UserRepository{db: db}
}

func (r *UserRepository) Create(user *User) error {
    return r.db.Create(user).Error
}

func (r *UserRepository) FindAll() ([]User, error) {
    var users []User
    err := r.db.Find(&users).Error
    return users, err
}

func (r *UserRepository) FindByID(id uint) (*User, error) {
    var user User
    err := r.db.First(&user, id).Error
    return &user, err
}

func (r *UserRepository) Update(user *User) error {
    return r.db.Save(user).Error
}

func (r *UserRepository) Delete(id uint) error {
    return r.db.Delete(&User{}, id).Error
}
```

### PostgreSQL Features

#### JSON Support

```go
type Product struct {
    ID        uint   `json:"id" gorm:"primaryKey"`
    Name      string `json:"name"`
    Metadata  string `json:"metadata" gorm:"type:jsonb"`
}

// Query with JSON
var products []Product
db.Where("metadata->>'category' = ?", "electronics").Find(&products)
```

#### Full-Text Search

```go
// Create GIN index
db.Exec("CREATE INDEX idx_products_name ON products USING gin(to_tsvector('english', name))")

// Search
db.Where("to_tsvector('english', name) @@ to_tsquery('english', ?)", searchTerm).Find(&products)
```

## Authentication & Security

### JWT Authentication

```go
// backend/internal/middleware/auth.go
import (
    "github.com/golang-jwt/jwt/v5"
    "time"
)

type Claims struct {
    UserID uint `json:"user_id"`
    jwt.RegisteredClaims
}

func GenerateToken(userID uint) (string, error) {
    claims := Claims{
        UserID: userID,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte("your-secret-key"))
}

func VerifyToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        return []byte("your-secret-key"), nil
    })

    if claims, ok := token.Claims.(*Claims); ok && token.Valid {
        return claims, nil
    }

    return nil, err
}
```

### CORS Configuration

```go
// backend/internal/middleware/cors.go
import (
    "github.com/gin-contrib/cors"
)

func CORSMiddleware() gin.HandlerFunc {
    return cors.New(cors.Config{
        AllowOrigins:     []string{"http://localhost:3000"},
        AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
        ExposeHeaders:    []string{"Content-Length"},
        AllowCredentials: true,
    })
}
```

## Testing

### Backend Testing

```go
// backend/internal/services/user_service_test.go
package services

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestUserService_CreateUser(t *testing.T) {
    // Setup
    repo := NewUserRepository(mockDB)
    service := NewUserService(repo)

    // Test
    user, err := service.CreateUser("John Doe", "john@example.com")

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, "John Doe", user.Name)
    assert.Equal(t, "john@example.com", user.Email)
}
```

### Frontend Testing

```typescript
// frontend/__tests__/api.test.ts
import { getUsers, createUser } from '@/lib/api';

describe('API Functions', () => {
    it('should fetch users', async () => {
        const users = await getUsers();
        expect(Array.isArray(users)).toBe(true);
    });

    it('should create a user', async () => {
        const user = await createUser({
            name: 'Test User',
            email: 'test@example.com'
        });
        expect(user.name).toBe('Test User');
    });
});
```

## Deployment

### Docker Setup

```dockerfile
# backend/Dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o server cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/server .
EXPOSE 8080
CMD ["./server"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: yourpassword
      POSTGRES_DB: yourdatabase
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    environment:
      DATABASE_URL: postgres://postgres:yourpassword@postgres:5432/yourdatabase

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  postgres_data:
```

## Best Practices

### Backend
1. Use dependency injection for better testability
2. Implement proper error handling
3. Use middleware for cross-cutting concerns
4. Follow RESTful API design principles
5. Implement rate limiting and caching
6. Use environment variables for configuration

### Frontend
1. Use Server Components for data fetching
2. Implement proper error boundaries
3. Use TypeScript for type safety
4. Optimize images and assets
5. Implement proper loading states
6. Use client-side caching where appropriate

### Database
1. Use migrations for schema changes
2. Implement proper indexing
3. Use transactions for multi-step operations
4. Implement connection pooling
5. Use prepared statements to prevent SQL injection
6. Regular backups

## Common Libraries

### Backend
- **Gin**: Fast web framework
- **GORM**: Popular ORM
- **Gorose**: Laravel-like ORM
- **Zorm**: Lightweight ORM
- **JWT**: Authentication
- **Redis**: Caching

### Frontend
- **Next.js**: React framework
- **React Query**: Data fetching
- **Zustand**: State management
- **Tailwind CSS**: Styling
- **TypeScript**: Type safety

## Troubleshooting

### Connection Issues
- Check PostgreSQL is running
- Verify connection string
- Check firewall settings
- Verify database credentials

### CORS Issues
- Configure CORS middleware properly
- Check frontend API URL
- Verify backend is accessible

### Performance Issues
- Implement database indexing
- Use connection pooling
- Implement caching
- Optimize queries
- Use CDN for static assets

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Golang Documentation](https://golang.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [GORM Documentation](https://gorm.io/docs/)
- [Gin Framework](https://gin-gonic.com/docs/)

## Conclusion

This stack provides a powerful combination of modern frontend, high-performance backend, and robust database. The separation of concerns allows for independent development and deployment of frontend and backend components while maintaining a clean architecture.
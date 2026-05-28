# Next.js + Golang + PostgreSQL Quick Start Guide

## Quick Overview

This guide provides a quick start for building full-stack applications with Next.js (frontend), Golang (backend), and PostgreSQL (database).

## Prerequisites

- Node.js 18+ installed
- Go 1.21+ installed
- PostgreSQL 14+ installed
- Docker (optional, for containerized development)

## Quick Setup

### 1. Create Project Structure

```bash
mkdir my-fullstack-app
cd my-fullstack-app

# Create directories
mkdir frontend backend
```

### 2. Initialize Frontend (Next.js)

```bash
cd frontend
npx create-next-app@latest .
# Select: TypeScript, Tailwind CSS, App Router, ESLint

# Install dependencies
npm install
```

### 3. Initialize Backend (Golang)

```bash
cd ../backend
go mod init github.com/yourusername/my-fullstack-app/backend

# Install dependencies
go get github.com/gin-gonic/gin
go get gorm.io/gorm
go get gorm.io/driver/postgres
go get github.com/lib/pq
```

### 4. Setup Database

```bash
# Using Docker
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=myapp \
  -p 5432:5432 \
  postgres:16

# Or using local installation
createdb myapp
```

### 5. Create Basic Backend Server

```go
// backend/cmd/server/main.go
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
    dsn := "host=localhost user=postgres password=postgres dbname=myapp port=5432 sslmode=disable"
    db, _ = gorm.Open(postgres.Open(dsn), &gorm.Config{})

    // Auto migrate
    db.AutoMigrate(&User{})

    // Setup router
    r := gin.Default()

    // Routes
    r.GET("/users", getUsers)
    r.POST("/users", createUser)

    r.Run(":8080")
}

func getUsers(c *gin.Context) {
    var users []User
    db.Find(&users)
    c.JSON(200, users)
}

func createUser(c *gin.Context) {
    var user User
    c.BindJSON(&user)
    db.Create(&user)
    c.JSON(201, user)
}
```

### 6. Create Frontend API Client

```typescript
// frontend/lib/api.ts
const API_BASE_URL = 'http://localhost:8080';

export interface User {
    id: number;
    name: string;
    email: string;
}

export async function getUsers(): Promise<User[]> {
    const response = await fetch(`${API_BASE_URL}/users`);
    return response.json();
}

export async function createUser(user: Omit<User, 'id'>): Promise<User> {
    const response = await fetch(`${API_BASE_URL}/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(user),
    });
    return response.json();
}
```

### 7. Create Frontend Page

```typescript
// frontend/app/users/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { getUsers, createUser, User } from '@/lib/api';

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        const data = await getUsers();
        setUsers(data);
        setLoading(false);
    };

    const handleCreate = async () => {
        const newUser = await createUser({
            name: 'New User',
            email: 'new@example.com'
        });
        setUsers([...users, newUser]);
    };

    if (loading) return <div>Loading...</div>;

    return (
        <div>
            <h1>Users</h1>
            <button onClick={handleCreate}>Create User</button>
            <ul>
                {users.map(user => (
                    <li key={user.id}>{user.name}</li>
                ))}
            </ul>
        </div>
    );
}
```

## Running the Application

### Start Backend

```bash
cd backend
go run cmd/server/main.go
```

### Start Frontend

```bash
cd frontend
npm run dev
```

### Access the Application

- Frontend: http://localhost:3000
- Backend API: http://localhost:8080
- Database: localhost:5432

## Common Commands

### Backend Commands

```bash
# Run backend
go run cmd/server/main.go

# Build backend
go build -o server cmd/server/main.go

# Run tests
go test ./...

# Run with coverage
go test -cover ./...

# Format code
go fmt ./...

# Lint code
go vet ./...
```

### Frontend Commands

```bash
# Run frontend
npm run dev

# Build frontend
npm run build

# Run tests
npm test

# Run lint
npm run lint

# Format code
npm run format
```

### Database Commands

```bash
# Connect to database
psql -U postgres -d myapp

# Run migrations
migrate -path migrations -database "postgres://postgres:postgres@localhost:5432/myapp?sslmode=disable" up

# Backup database
pg_dump -U postgres myapp > backup.sql

# Restore database
psql -U postgres myapp < backup.sql
```

## Project Structure

```
my-fullstack-app/
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
│   │   └── services/     # Business logic
│   ├── pkg/              # Public libraries
│   ├── migrations/       # Database migrations
│   └── go.mod
└── docker-compose.yml    # Container orchestration
```

## Key Concepts

### Backend Architecture

1. **Handler Layer**: HTTP request handling
2. **Service Layer**: Business logic
3. **Repository Layer**: Data access
4. **Model Layer**: Data structures

### Frontend Architecture

1. **Server Components**: Default in Next.js App Router
2. **Client Components**: Interactive components
3. **API Routes**: Backend integration
4. **State Management**: React hooks and libraries

### Database Operations

1. **CRUD Operations**: Create, Read, Update, Delete
2. **Relationships**: One-to-many, many-to-many
3. **Transactions**: ACID compliance
4. **Indexes**: Performance optimization

## Best Practices

### Backend

- Use dependency injection
- Implement proper error handling
- Use middleware for cross-cutting concerns
- Follow RESTful API design
- Implement authentication and authorization
- Use environment variables for configuration

### Frontend

- Use Server Components for data fetching
- Implement proper error boundaries
- Use TypeScript for type safety
- Optimize images and assets
- Implement proper loading states
- Use client-side caching where appropriate

### Database

- Use migrations for schema changes
- Implement proper indexing
- Use transactions for multi-step operations
- Implement connection pooling
- Use prepared statements
- Regular backups

## Common Libraries

### Backend

- **Gin**: Fast web framework
- **GORM**: Popular ORM
- **Gorose**: Laravel-like ORM
- **JWT**: Authentication
- **Redis**: Caching

### Frontend

- **Next.js**: React framework
- **React Query**: Data fetching
- **Zustand**: State management
- **Tailwind CSS**: Styling
- **TypeScript**: Type safety

## Troubleshooting

### Backend Issues

1. **Database connection failed**
   - Check PostgreSQL is running
   - Verify connection string
   - Check firewall settings

2. **Port already in use**
   - Change port in code
   - Kill process using port
   - Use different port

3. **Import errors**
   - Check go.mod
   - Run `go mod tidy`
   - Verify import paths

### Frontend Issues

1. **API calls failing**
   - Check CORS configuration
   - Verify API URL
   - Check backend is running

2. **Build errors**
   - Check TypeScript errors
   - Verify dependencies
   - Clear node_modules

3. **Performance issues**
   - Implement caching
   - Optimize images
   - Use code splitting

### Database Issues

1. **Connection timeout**
   - Check database is running
   - Verify credentials
   - Check network connectivity

2. **Migration errors**
   - Check migration files
   - Verify database schema
   - Rollback if needed

3. **Performance issues**
   - Add indexes
   - Optimize queries
   - Use connection pooling

## Next Steps

1. **Authentication**: Implement JWT or OAuth
2. **Testing**: Add unit and integration tests
3. **Deployment**: Set up CI/CD pipeline
4. **Monitoring**: Implement logging and monitoring
5. **Security**: Add rate limiting and security headers
6. **Performance**: Implement caching and optimization
7. **Documentation**: Add API documentation
8. **Backup**: Set up automated backups

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Golang Documentation](https://golang.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [GORM Documentation](https://gorm.io/docs/)
- [Gin Framework](https://gin-gonic.com/docs/)

## Conclusion

This quick start guide provides the foundation for building full-stack applications with Next.js, Golang, and PostgreSQL. Follow the best practices and explore the resources to build robust, scalable applications.
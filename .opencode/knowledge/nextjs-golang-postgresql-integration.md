# Next.js + Golang + PostgreSQL Integration Guide

## Architecture Overview

This guide explains how to integrate Next.js frontend with Golang backend and PostgreSQL database.

## Communication Flow

```
User Browser
    ↓
Next.js Frontend (Port 3000)
    ↓
HTTP/REST API
    ↓
Golang Backend (Port 8080)
    ↓
PostgreSQL Database (Port 5432)
```

## Integration Methods

### Method 1: Direct API Calls from Next.js

#### Setup Backend

```go
// backend/cmd/server/main.go
package main

import (
    "github.com/gin-gonic/gin"
    "github.com/gorilla/mux"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

var db *gorm.DB

func main() {
    // Database connection
    dsn := "host=localhost user=postgres password=yourpassword dbname=yourdatabase port=5432 sslmode=disable"
    db, _ = gorm.Open(postgres.Open(dsn), &gorm.Config{})

    // Setup router
    r := gin.Default()

    // Health check
    r.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    // User routes
    r.GET("/api/users", getUsers)
    r.POST("/api/users", createUser)
    r.GET("/api/users/:id", getUser)
    r.PUT("/api/users/:id", updateUser)
    r.DELETE("/api/users/:id", deleteUser)

    r.Run(":8080")
}
```

#### Setup Frontend API Client

```typescript
// frontend/lib/api.ts
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

export interface User {
    id: number;
    name: string;
    email: string;
}

export async function getUsers(): Promise<User[]> {
    const response = await fetch(`${API_BASE_URL}/api/users`);
    if (!response.ok) {
        throw new Error('Failed to fetch users');
    }
    return response.json();
}

export async function createUser(user: Omit<User, 'id'>): Promise<User> {
    const response = await fetch(`${API_BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(user),
    });
    if (!response.ok) {
        throw new Error('Failed to create user');
    }
    return response.json();
}

export async function getUser(id: number): Promise<User> {
    const response = await fetch(`${API_BASE_URL}/api/users/${id}`);
    if (!response.ok) {
        throw new Error('Failed to fetch user');
    }
    return response.json();
}

export async function updateUser(id: number, user: Partial<User>): Promise<User> {
    const response = await fetch(`${API_BASE_URL}/api/users/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(user),
    });
    if (!response.ok) {
        throw new Error('Failed to update user');
    }
    return response.json();
}

export async function deleteUser(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/api/users/${id}`, {
        method: 'DELETE',
    });
    if (!response.ok) {
        throw new Error('Failed to delete user');
    }
}
```

#### Use in Next.js Components

```typescript
// frontend/app/users/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { getUsers, createUser, User } from '@/lib/api';

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            setLoading(true);
            const data = await getUsers();
            setUsers(data);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'An error occurred');
        } finally {
            setLoading(false);
        }
    };

    const handleCreate = async () => {
        try {
            const newUser = await createUser({
                name: 'New User',
                email: 'new@example.com'
            });
            setUsers([...users, newUser]);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to create user');
        }
    };

    if (loading) return <div>Loading...</div>;
    if (error) return <div>Error: {error}</div>;

    return (
        <div>
            <h1>Users</h1>
            <button onClick={handleCreate}>Create User</button>
            <ul>
                {users.map(user => (
                    <li key={user.id}>
                        {user.name} - {user.email}
                    </li>
                ))}
            </ul>
        </div>
    );
}
```

### Method 2: Next.js API Routes as Proxy

#### Setup Next.js API Routes

```typescript
// frontend/app/api/users/route.ts
import { NextResponse } from 'next/server';
import { getUsers as getBackendUsers, createUser as createBackendUser } from '@/lib/api';

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

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const user = await createBackendUser(body);
        return NextResponse.json(user, { status: 201 });
    } catch (error) {
        return NextResponse.json(
            { error: 'Failed to create user' },
            { status: 500 }
        );
    }
}
```

#### Use in Components

```typescript
// frontend/app/users/page.tsx
'use client';

import { useEffect, useState } from 'react';

export default function UsersPage() {
    const [users, setUsers] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            const response = await fetch('/api/users');
            const data = await response.json();
            setUsers(data);
        } catch (error) {
            console.error('Failed to fetch users:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) return <div>Loading...</div>;

    return (
        <div>
            <h1>Users</h1>
            <ul>
                {users.map(user => (
                    <li key={user.id}>{user.name}</li>
                ))}
            </ul>
        </div>
    );
}
```

### Method 3: GraphQL Integration

#### Setup GraphQL Backend

```go
// backend/cmd/server/main.go
package main

import (
    "github.com/graphql-go/graphql"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

var db *gorm.DB

func main() {
    // Database connection
    dsn := "host=localhost user=postgres password=yourpassword dbname=yourdatabase port=5432 sslmode=disable"
    db, _ = gorm.Open(postgres.Open(dsn), &gorm.Config{})

    // GraphQL schema
    userType := graphql.NewObject(graphql.ObjectConfig{
        Name: "User",
        Fields: graphql.Fields{
            "id": &graphql.Field{
                Type: graphql.Int,
            },
            "name": &graphql.Field{
                Type: graphql.String,
            },
            "email": &graphql.Field{
                Type: graphql.String,
            },
        },
    })

    queryType := graphql.NewObject(graphql.ObjectConfig{
        Name: "Query",
        Fields: graphql.Fields{
            "users": &graphql.Field{
                Type: graphql.NewList(userType),
                Resolve: func(p graphql.ResolveParams) (interface{}, error) {
                    var users []User
                    db.Find(&users)
                    return users, nil
                },
            },
        },
    })

    schema, _ := graphql.NewSchema(graphql.SchemaConfig{
        Query: queryType,
    })

    // GraphQL server
    http.HandleFunc("/graphql", func(w http.ResponseWriter, r *http.Request) {
        result := graphql.Do(graphql.Params{
            Schema:        schema,
            RequestString: r.URL.Query().Get("query"),
        })
        json.NewEncoder(w).Encode(result)
    })

    http.ListenAndServe(":8080", nil)
}
```

#### Setup GraphQL Client

```typescript
// frontend/lib/graphql.ts
const GRAPHQL_URL = process.env.NEXT_PUBLIC_GRAPHQL_URL || 'http://localhost:8080/graphql';

export async function fetchUsers() {
    const query = `
        query {
            users {
                id
                name
                email
            }
        }
    `;

    const response = await fetch(GRAPHQL_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query }),
    });

    const data = await response.json();
    return data.data.users;
}
```

## Environment Configuration

### .env.local (Frontend)

```env
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_GRAPHQL_URL=http://localhost:8080/graphql
```

### .env (Backend)

```env
DATABASE_URL=postgres://postgres:yourpassword@localhost:5432/yourdatabase
JWT_SECRET=your-secret-key
PORT=8080
```

## CORS Configuration

### Backend CORS Setup

```go
// backend/internal/middleware/cors.go
package middleware

import (
    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
)

func CORSMiddleware() gin.HandlerFunc {
    return cors.New(cors.Config{
        AllowOrigins:     []string{"http://localhost:3000"},
        AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
        ExposeHeaders:    []string{"Content-Length"},
        AllowCredentials: true,
        MaxAge:           12 * time.Hour,
    })
}
```

### Apply CORS Middleware

```go
// backend/cmd/server/main.go
func main() {
    r := gin.Default()
    r.Use(middleware.CORSMiddleware())
    // ... rest of the code
}
```

## Error Handling

### Backend Error Handling

```go
// backend/internal/handlers/user_handler.go
package handlers

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

type ErrorResponse struct {
    Error   string `json:"error"`
    Message string `json:"message"`
}

func GetUserHandler(c *gin.Context) {
    id := c.Param("id")

    var user User
    if err := db.First(&user, id).Error; err != nil {
        c.JSON(http.StatusNotFound, ErrorResponse{
            Error:   "User not found",
            Message: "No user found with the provided ID",
        })
        return
    }

    c.JSON(http.StatusOK, user)
}

func CreateUserHandler(c *gin.Context) {
    var input UserInput
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Invalid input",
            Message: err.Error(),
        })
        return
    }

    user := User{
        Name:  input.Name,
        Email: input.Email,
    }

    if err := db.Create(&user).Error; err != nil {
        c.JSON(http.StatusInternalServerError, ErrorResponse{
            Error:   "Database error",
            Message: err.Error(),
        })
        return
    }

    c.JSON(http.StatusCreated, user)
}
```

### Frontend Error Handling

```typescript
// frontend/lib/api.ts
export async function safeFetch<T>(url: string, options?: RequestInit): Promise<T> {
    try {
        const response = await fetch(url, options);

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
        }

        return response.json();
    } catch (error) {
        if (error instanceof Error) {
            throw error;
        }
        throw new Error('An unknown error occurred');
    }
}
```

## Authentication Integration

### JWT Implementation

```go
// backend/internal/middleware/auth.go
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
            return
        }

        tokenString := strings.TrimPrefix(authHeader, "Bearer ")
        claims := &Claims{}

        token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
            return []byte("your-secret-key"), nil
        })

        if err != nil || !token.Valid {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
            return
        }

        c.Set("userID", claims.UserID)
        c.Next()
    }
}
```

### Protected Routes

```go
// backend/internal/handlers/user_handler.go
func UpdateUserHandler(c *gin.Context) {
    userID := c.GetUint("userID")
    id := c.Param("id")

    if userID != id {
        c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized"})
        return
    }

    // Update user logic
}
```

## Testing Integration

### Backend Tests

```go
// backend/internal/handlers/user_handler_test.go
package handlers

import (
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
)

func TestGetUserHandler(t *testing.T) {
    // Setup
    router := gin.Default()
    router.GET("/users/:id", GetUserHandler)

    // Test
    req, _ := http.NewRequest("GET", "/users/1", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    // Assert
    assert.Equal(t, http.StatusOK, w.Code)
}
```

### Frontend Tests

```typescript
// frontend/__tests__/api.test.ts
import { getUsers, createUser } from '@/lib/api';

describe('API Integration', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('should fetch users from backend', async () => {
        const mockUsers = [
            { id: 1, name: 'John Doe', email: 'john@example.com' }
        ];

        global.fetch = jest.fn().mockResolvedValue({
            ok: true,
            json: async () => mockUsers,
        });

        const users = await getUsers();
        expect(users).toEqual(mockUsers);
    });

    it('should create a user', async () => {
        const mockUser = { id: 1, name: 'New User', email: 'new@example.com' };

        global.fetch = jest.fn().mockResolvedValue({
            ok: true,
            json: async () => mockUser,
        });

        const user = await createUser({ name: 'New User', email: 'new@example.com' });
        expect(user).toEqual(mockUser);
    });
});
```

## Performance Optimization

### Backend Optimization

```go
// backend/internal/middleware/cache.go
package middleware

import (
    "github.com/gin-gonic/gin"
    "time"
)

func CacheMiddleware(duration time.Duration) gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Header("Cache-Control", "public, max-age="+string(duration.Seconds()))
        c.Next()
    }
}
```

### Frontend Optimization

```typescript
// frontend/lib/cache.ts
export function cacheData<T>(key: string, T, ttl: number = 5 * 60 * 1000): void {
    const item = {
        data,
        timestamp: Date.now(),
    };
    localStorage.setItem(key, JSON.stringify(item));
}

export function getCachedData<T>(key: string): T | null {
    const itemStr = localStorage.getItem(key);
    if (!itemStr) return null;

    const item = JSON.parse(itemStr);
    const now = Date.now();

    if (now - item.timestamp > 5 * 60 * 1000) {
        localStorage.removeItem(key);
        return null;
    }

    return item.data;
}
```

## Monitoring and Logging

### Backend Logging

```go
// backend/internal/middleware/logger.go
package middleware

import (
    "log"
    "time"
    "github.com/gin-gonic/gin"
)

func LoggerMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        path := c.Request.URL.Path
        query := c.Request.URL.RawQuery

        c.Next()

        latency := time.Since(start)
        status := c.Writer.Status()
        clientIP := c.ClientIP()
        method := c.Request.Method

        log.Printf("[%s] %s %s %s %d %v",
            method,
            path,
            query,
            clientIP,
            status,
            latency,
        )
    }
}
```

## Deployment Considerations

### Production Configuration

```go
// backend/cmd/server/main.go
func main() {
    // Production mode
    if os.Getenv("ENV") == "production" {
        gin.SetMode(gin.ReleaseMode)
    }

    // Load environment variables
    dbHost := os.Getenv("DB_HOST")
    dbPort := os.Getenv("DB_PORT")
    dbUser := os.Getenv("DB_USER")
    dbPassword := os.Getenv("DB_PASSWORD")
    dbName := os.Getenv("DB_NAME")

    // Build connection string
    dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
        dbHost, dbUser, dbPassword, dbName, dbPort)

    // Connect to database
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }

    // Setup server
    r := gin.Default()
    r.Use(middleware.CORSMiddleware())
    r.Use(middleware.LoggerMiddleware())

    // Routes...
    r.Run(":" + os.Getenv("PORT"))
}
```

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Ensure CORS middleware is configured correctly
   - Check frontend API URL matches backend URL
   - Verify AllowOrigins includes frontend URL

2. **Database Connection Issues**
   - Check PostgreSQL is running
   - Verify connection string format
   - Check firewall settings
   - Verify database credentials

3. **Authentication Issues**
   - Check JWT secret matches
   - Verify token format
   - Check token expiration

4. **Performance Issues**
   - Implement database indexing
   - Use connection pooling
   - Implement caching
   - Optimize queries

## Best Practices

1. Use environment variables for configuration
2. Implement proper error handling
3. Use HTTPS in production
4. Implement rate limiting
5. Use proper logging
6. Implement monitoring
7. Use connection pooling
8. Implement caching
9. Use prepared statements
10. Regular backups

## Conclusion

This integration guide provides comprehensive coverage of connecting Next.js frontend with Golang backend and PostgreSQL database. Follow these patterns and best practices to build robust, scalable applications.
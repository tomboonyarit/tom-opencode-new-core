# PostgreSQL with Go using sqlc - Complete Guide

## Overview

sqlc is a tool that generates type-safe code from SQL queries. It dramatically improves the developer experience of working with relational databases without sacrificing type-safety or runtime performance.

## 1. sqlc Setup and Configuration

### Installation

```bash
# Install sqlc
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

# Verify installation
sqlc version
```

### Project Structure

```
myproject/
├── go.mod
├── go.sum
├── sqlc.json          # sqlc configuration file
├── schema/            # Database schema files
│   ├── 0001_init.sql
│   └── 0002_add_table.sql
├── query/             # SQL query files
│   ├── users.sql
│   └── posts.sql
└── internal/
    ├── db/            # Generated code (do not edit)
    │   ├── db.go
    │   ├── models.go
    │   ├── querier.go
    │   └── users.sql.go
    ├── repository/    # Repository layer
    │   └── user_repository.go
    └── controller/    # Controller layer
        └── user_controller.go
```

### sqlc.json Configuration

```json
{
  "version": "1",
  "packages": [
    {
      "path": "internal/db",
      "name": "db",
      "schema": "schema",
      "queries": "query",
      "engine": "postgresql",
      "sql_package": "database/sql",
      "emit_json_tags": true,
      "emit_prepared_queries": true,
      "emit_interface": true
    }
  ]
}
```

**Configuration Options:**

- `version`: sqlc version (must be "1")
- `packages`: Array of package configurations
  - `path`: Output directory for generated code
  - `name`: Package name for generated code
  - `schema`: Directory containing schema files
  - `queries`: Directory containing query files
  - `engine`: Database engine (postgresql, mysql, sqlite)
  - `sql_package`: Go SQL package to use
  - `emit_json_tags`: Generate JSON tags for structs
  - `emit_prepared_queries`: Generate prepared statements
  - `emit_interface`: Generate an interface for the queries

## 2. Defining Database Models Using sqlc

### Schema Files

sqlc uses SQL DDL statements to define database models. Schema files should be organized with migration-style naming:

**schema/0001_init.sql**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_posts_user_id ON posts(user_id);
```

**schema/0002_add_profile.sql**
```sql
CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    bio TEXT,
    avatar_url TEXT,
    website TEXT
);
```

### Custom Types and Enums

sqlc supports PostgreSQL types and custom types:

**schema/0003_custom_types.sql**
```sql
-- Custom enum type
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');

-- Custom type with custom scanner/valuer
CREATE TYPE rating AS ENUM ('poor', 'fair', 'good', 'excellent');

-- Table using custom types
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER,
    rating rating NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 3. Generating Go Code from SQL Queries

### Query Files

Query files contain SQL statements with special comments that tell sqlc how to generate Go code:

**query/users.sql**
```sql
-- name: ListUsers :many
SELECT * FROM users ORDER BY created_at DESC;

-- name: GetUser :one
SELECT * FROM users WHERE id = $1;

-- name: CreateUser :one
INSERT INTO users (email, username, password_hash)
VALUES ($1, $2, $3)
RETURNING *;

-- name: UpdateUser :one
UPDATE users
SET email = $2, username = $3, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = $1;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1;
```

**query/posts.sql**
```sql
-- name: ListPosts :many
SELECT * FROM posts ORDER BY created_at DESC;

-- name: GetPost :one
SELECT * FROM posts WHERE id = $1;

-- name: CreatePost :one
INSERT INTO posts (user_id, title, content)
VALUES ($1, $2, $3)
RETURNING *;

-- name: UpdatePost :one
UPDATE posts
SET title = $2, content = $3, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: DeletePost :exec
DELETE FROM posts WHERE id = $1;

-- name: GetPostsByUser :many
SELECT * FROM posts WHERE user_id = $1 ORDER BY created_at DESC;
```

### Generating Code

```bash
# Generate Go code from SQL queries
sqlc generate

# Generate with specific configuration
sqlc generate --file sqlc.json

# Generate with verbose output
sqlc generate -v
```

### Generated Code Structure

sqlc generates three main files:

**internal/db/db.go**
```go
// Code generated by sqlc. DO NOT EDIT.
// versions:
// sqlc v1.31.1

package db

import (
    "context"
    "database/sql"
    "fmt"
)

type DBTX interface {
    ExecContext(context.Context, string, ...interface{}) (sql.Result, error)
    PrepareContext(context.Context, string) (*sql.Stmt, error)
    QueryContext(context.Context, string, ...interface{}) (*sql.Rows, error)
    QueryRowContext(context.Context, string, ...interface{}) *sql.Row
}

func New(db DBTX) *Queries {
    return &Queries{db: db}
}

func Prepare(ctx context.Context, db DBTX) (*Queries, error) {
    q := Queries{db: db}
    var err error
    // Prepared statements are initialized here
    return &q, nil
}

func (q *Queries) Close() error {
    // Cleanup prepared statements
    return nil
}

func (q *Queries) WithTx(tx *sql.Tx) *Queries {
    return &Queries{
        db: tx,
        tx: tx,
    }
}

type Queries struct {
    db DBTX
    tx *sql.Tx
    // Prepared statements
}
```

**internal/db/models.go**
```go
// Code generated by sqlc. DO NOT EDIT.
// versions:
// sqlc v1.31.1

package db

import (
    "database/sql"
    "database/sql/driver"
    "fmt"
    "time"
)

// UserStatus represents the status of a user
type UserStatus string

const (
    UserStatusActive   UserStatus = "active"
    UserStatusInactive UserStatus = "inactive"
    UserStatusSuspended UserStatus = "suspended"
)

func (e *UserStatus) Scan(src interface{}) error {
    switch s := src.(type) {
    case []byte:
        *e = UserStatus(s)
    case string:
        *e = UserStatus(s)
    default:
        return fmt.Errorf("unsupported scan type for UserStatus: %T", src)
    }
    return nil
}

type NullUserStatus struct {
    UserStatus UserStatus `json:"user_status"`
    Valid bool `json:"valid"` // Valid is true if UserStatus is not NULL
}

func (ns *NullUserStatus) Scan(value interface{}) error {
    if value == nil {
        ns.UserStatus, ns.Valid = "", false
        return nil
    }
    ns.Valid = true
    return ns.UserStatus.Scan(value)
}

func (ns NullUserStatus) Value() (driver.Value, error) {
    if !ns.Valid {
        return nil, nil
    }
    return string(ns.UserStatus), nil
}

type User struct {
    ID        int32         `json:"id"`
    Email     string        `json:"email"`
    Username  string        `json:"username"`
    PasswordHash string     `json:"password_hash"`
    Status    UserStatus    `json:"status"`
    CreatedAt time.Time     `json:"created_at"`
    UpdatedAt time.Time     `json:"updated_at"`
}

type Post struct {
    ID        int32       `json:"id"`
    UserID    int32       `json:"user_id"`
    Title     string      `json:"title"`
    Content   string      `json:"content"`
    CreatedAt time.Time   `json:"created_at"`
    UpdatedAt time.Time   `json:"updated_at"`
}
```

**internal/db/querier.go**
```go
// Code generated by sqlc. DO NOT EDIT.
// versions:
// sqlc v1.31.1

package db

import (
    "context"
)

type Querier interface {
    // ListUsers returns all users
    ListUsers(ctx context.Context) ([]User, error)

    // GetUser returns a single user by ID
    GetUser(ctx context.Context, id int32) (User, error)

    // CreateUser creates a new user
    CreateUser(ctx context.Context, arg CreateUserParams) (User, error)

    // UpdateUser updates a user
    UpdateUser(ctx context.Context, arg UpdateUserParams) (User, error)

    // DeleteUser deletes a user
    DeleteUser(ctx context.Context, id int32) error

    // GetUserByEmail returns a user by email
    GetUserByEmail(ctx context.Context, email string) (User, error)

    // ListPosts returns all posts
    ListPosts(ctx context.Context) ([]Post, error)

    // GetPost returns a single post by ID
    GetPost(ctx context.Context, id int32) (Post, error)

    // CreatePost creates a new post
    CreatePost(ctx context.Context, arg CreatePostParams) (Post, error)

    // UpdatePost updates a post
    UpdatePost(ctx context.Context, arg UpdatePostParams) (Post, error)

    // DeletePost deletes a post
    DeletePost(ctx context.Context, id int32) error

    // GetPostsByUser returns posts by user ID
    GetPostsByUser(ctx context.Context, userID int32) ([]Post, error)
}

var _ Querier = (*Queries)(nil)
```

## 4. Controller Structure and Patterns

### Repository Pattern

The repository layer abstracts database operations:

**internal/repository/user_repository.go**
```go
package repository

import (
    "context"
    "errors"
    "myproject/internal/db"
)

type UserRepository struct {
    q *db.Queries
}

func NewUserRepository(q *db.Queries) *UserRepository {
    return &UserRepository{q: q}
}

// CreateUser creates a new user
func (r *UserRepository) CreateUser(ctx context.Context, email, username, passwordHash string) (*db.User, error) {
    user, err := r.q.CreateUser(ctx, db.CreateUserParams{
        Email:         email,
        Username:      username,
        PasswordHash:  passwordHash,
    })
    if err != nil {
        return nil, err
    }
    return &user, nil
}

// GetUserByID retrieves a user by ID
func (r *UserRepository) GetUserByID(ctx context.Context, id int32) (*db.User, error) {
    user, err := r.q.GetUser(ctx, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, err
    }
    return &user, nil
}

// GetUserByEmail retrieves a user by email
func (r *UserRepository) GetUserByEmail(ctx context.Context, email string) (*db.User, error) {
    user, err := r.q.GetUserByEmail(ctx, email)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, err
    }
    return &user, nil
}

// ListUsers retrieves all users
func (r *UserRepository) ListUsers(ctx context.Context) ([]db.User, error) {
    return r.q.ListUsers(ctx)
}

// UpdateUser updates a user
func (r *UserRepository) UpdateUser(ctx context.Context, id int32, email, username string) (*db.User, error) {
    user, err := r.q.UpdateUser(ctx, db.UpdateUserParams{
        ID:       id,
        Email:    email,
        Username: username,
    })
    if err != nil {
        return nil, err
    }
    return &user, nil
}

// DeleteUser deletes a user
func (r *UserRepository) DeleteUser(ctx context.Context, id int32) error {
    return r.q.DeleteUser(ctx, id)
}

// Error definitions
var (
    ErrUserNotFound = errors.New("user not found")
    ErrUserExists   = errors.New("user already exists")
)
```

### Controller Pattern

The controller layer handles HTTP requests and coordinates between repository and service layers:

**internal/controller/user_controller.go**
```go
package controller

import (
    "context"
    "encoding/json"
    "net/http"
    "strconv"

    "myproject/internal/repository"
    "myproject/internal/db"
)

type UserController struct {
    userRepo *repository.UserRepository
}

func NewUserController(userRepo *repository.UserRepository) *UserController {
    return &UserController{userRepo: userRepo}
}

// CreateUserRequest represents the request body for creating a user
type CreateUserRequest struct {
    Email         string `json:"email"`
    Username      string `json:"username"`
    PasswordHash  string `json:"password_hash"`
}

// CreateUserResponse represents the response for creating a user
type CreateUserResponse struct {
    ID       int32  `json:"id"`
    Email    string `json:"email"`
    Username string `json:"username"`
}

// CreateUser handles POST /users
func (c *UserController) CreateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }

    // Validate input
    if req.Email == "" || req.Username == "" || req.PasswordHash == "" {
        http.Error(w, "Email, username, and password are required", http.StatusBadRequest)
        return
    }

    // Check if user already exists
    existingUser, err := c.userRepo.GetUserByEmail(ctx, req.Email)
    if err == nil && existingUser != nil {
        http.Error(w, "User already exists", http.StatusConflict)
        return
    }

    // Create user
    user, err := c.userRepo.CreateUser(ctx, req.Email, req.Username, req.PasswordHash)
    if err != nil {
        http.Error(w, "Failed to create user", http.StatusInternalServerError)
        return
    }

    // Return response
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(CreateUserResponse{
        ID:       user.ID,
        Email:    user.Email,
        Username: user.Username,
    })
}

// GetUser handles GET /users/:id
func (c *UserController) GetUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    // Extract user ID from URL
    idStr := r.URL.Path[len("/users/"):]
    id, err := strconv.ParseInt(idStr, 10, 32)
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }

    // Get user
    user, err := c.userRepo.GetUserByID(ctx, int32(id))
    if err != nil {
        if err == repository.ErrUserNotFound {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        http.Error(w, "Failed to get user", http.StatusInternalServerError)
        return
    }

    // Return response
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

// ListUsers handles GET /users
func (c *UserController) ListUsers(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    // Get all users
    users, err := c.userRepo.ListUsers(ctx)
    if err != nil {
        http.Error(w, "Failed to list users", http.StatusInternalServerError)
        return
    }

    // Return response
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(users)
}

// UpdateUser handles PUT /users/:id
func (c *UserController) UpdateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    // Extract user ID from URL
    idStr := r.URL.Path[len("/users/"):]
    id, err := strconv.ParseInt(idStr, 10, 32)
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }

    var req struct {
        Email    string `json:"email"`
        Username string `json:"username"`
    }

    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }

    // Update user
    user, err := c.userRepo.UpdateUser(ctx, int32(id), req.Email, req.Username)
    if err != nil {
        if err == repository.ErrUserNotFound {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        http.Error(w, "Failed to update user", http.StatusInternalServerError)
        return
    }

    // Return response
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

// DeleteUser handles DELETE /users/:id
func (c *UserController) DeleteUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    // Extract user ID from URL
    idStr := r.URL.Path[len("/users/"):]
    id, err := strconv.ParseInt(idStr, 10, 32)
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }

    // Delete user
    err = c.userRepo.DeleteUser(ctx, int32(id))
    if err != nil {
        if err == repository.ErrUserNotFound {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        http.Error(w, "Failed to delete user", http.StatusInternalServerError)
        return
    }

    // Return success response
    w.WriteHeader(http.StatusNoContent)
}
```

### Service Layer (Optional)

The service layer adds business logic:

**internal/service/user_service.go**
```go
package service

import (
    "context"
    "errors"
    "myproject/internal/repository"
    "myproject/internal/db"
)

type UserService struct {
    userRepo *repository.UserRepository
}

func NewUserService(userRepo *repository.UserRepository) *UserService {
    return &UserService{userRepo: userRepo}
}

// CreateUser creates a new user with validation
func (s *UserService) CreateUser(ctx context.Context, email, username, passwordHash string) (*db.User, error) {
    // Validate email format
    if !isValidEmail(email) {
        return nil, errors.New("invalid email format")
    }

    // Check if user already exists
    existingUser, err := s.userRepo.GetUserByEmail(ctx, email)
    if err == nil && existingUser != nil {
        return nil, errors.New("user already exists")
    }

    // Create user
    user, err := s.userRepo.CreateUser(ctx, email, username, passwordHash)
    if err != nil {
        return nil, err
    }

    return user, nil
}

// isValidEmail validates email format
func isValidEmail(email string) bool {
    // Simple email validation
    return len(email) > 0 && contains(email, "@") && contains(email, ".")
}

func contains(s, substr string) bool {
    return len(s) >= len(substr) && (s == substr || len(s) > len(substr) && (s[:len(substr)] == substr || s[len(s)-len(substr):] == substr || contains(s[1:], substr)))
}
```

## 5. Best Practices for Organizing Models, Repositories, and Controllers

### Directory Structure

```
internal/
├── db/              # Generated by sqlc (do not edit)
│   ├── db.go
│   ├── models.go
│   ├── querier.go
│   └── [query_name].sql.go
├── repository/      # Data access layer
│   ├── user_repository.go
│   ├── post_repository.go
│   └── interfaces.go
├── service/         # Business logic layer
│   ├── user_service.go
│   ├── post_service.go
│   └── interfaces.go
└── controller/      # HTTP handlers
    ├── user_controller.go
    ├── post_controller.go
    └── middleware.go
```

### Naming Conventions

- **Schema files**: `0001_init.sql`, `0002_add_table.sql` (migration-style)
- **Query files**: `users.sql`, `posts.sql` (plural, singular naming)
- **Generated files**: `users.sql.go`, `posts.sql.go`
- **Repository files**: `user_repository.go`, `post_repository.go`
- **Service files**: `user_service.go`, `post_service.go`
- **Controller files**: `user_controller.go`, `post_controller.go`

### Error Handling

```go
// Define custom errors
var (
    ErrUserNotFound = errors.New("user not found")
    ErrUserExists   = errors.New("user already exists")
    ErrInvalidInput = errors.New("invalid input")
)

// Use errors.Is for error comparison
if errors.Is(err, sql.ErrNoRows) {
    return ErrUserNotFound
}

// Wrap errors with context
if err != nil {
    return fmt.Errorf("failed to create user: %w", err)
}
```

### Context Usage

```go
// Always pass context through the call stack
func (r *UserRepository) CreateUser(ctx context.Context, email, username, passwordHash string) (*db.User, error) {
    user, err := r.q.CreateUser(ctx, db.CreateUserParams{
        Email:         email,
        Username:      username,
        PasswordHash:  passwordHash,
    })
    if err != nil {
        return nil, fmt.Errorf("repository: %w", err)
    }
    return &user, nil
}
```

### Transaction Management

```go
// Use transactions for multi-step operations
func (s *UserService) CreateUserWithProfile(ctx context.Context, email, username, passwordHash, bio string) (*db.User, error) {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return nil, err
    }
    defer tx.Rollback()

    // Create user
    user, err := s.userRepo.CreateUserTx(ctx, tx, email, username, passwordHash)
    if err != nil {
        return nil, err
    }

    // Create profile
    _, err = s.profileRepo.CreateProfileTx(ctx, tx, user.ID, bio)
    if err != nil {
        return nil, err
    }

    // Commit transaction
    if err := tx.Commit(); err != nil {
        return nil, err
    }

    return user, nil
}
```

## 6. Example Code Structure

### Complete Example: User Management System

**schema/0001_users.sql**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    status user_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
```

**query/users.sql**
```sql
-- name: ListUsers :many
SELECT * FROM users ORDER BY created_at DESC;

-- name: GetUser :one
SELECT * FROM users WHERE id = $1;

-- name: CreateUser :one
INSERT INTO users (email, username, password_hash, status)
VALUES ($1, $2, $3, 'active')
RETURNING *;

-- name: UpdateUser :one
UPDATE users
SET email = $2, username = $3, status = $4, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = $1;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1;

-- name: GetUserByUsername :one
SELECT * FROM users WHERE username = $1;
```

**internal/repository/user_repository.go**
```go
package repository

import (
    "context"
    "errors"
    "myproject/internal/db"
)

type UserRepository struct {
    q *db.Queries
}

func NewUserRepository(q *db.Queries) *UserRepository {
    return &UserRepository{q: q}
}

func (r *UserRepository) CreateUser(ctx context.Context, email, username, passwordHash string) (*db.User, error) {
    user, err := r.q.CreateUser(ctx, db.CreateUserParams{
        Email:         email,
        Username:      username,
        PasswordHash:  passwordHash,
    })
    if err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) GetUserByID(ctx context.Context, id int32) (*db.User, error) {
    user, err := r.q.GetUser(ctx, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) GetUserByEmail(ctx context.Context, email string) (*db.User, error) {
    user, err := r.q.GetUserByEmail(ctx, email)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) GetUserByUsername(ctx context.Context, username string) (*db.User, error) {
    user, err := r.q.GetUserByUsername(ctx, username)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) ListUsers(ctx context.Context) ([]db.User, error) {
    return r.q.ListUsers(ctx)
}

func (r *UserRepository) UpdateUser(ctx context.Context, id int32, email, username string, status db.UserStatus) (*db.User, error) {
    user, err := r.q.UpdateUser(ctx, db.UpdateUserParams{
        ID:       id,
        Email:    email,
        Username: username,
        Status:   status,
    })
    if err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) DeleteUser(ctx context.Context, id int32) error {
    return r.q.DeleteUser(ctx, id)
}
```

**internal/controller/user_controller.go**
```go
package controller

import (
    "context"
    "encoding/json"
    "net/http"
    "strconv"

    "myproject/internal/repository"
    "myproject/internal/db"
)

type UserController struct {
    userRepo *repository.UserRepository
}

func NewUserController(userRepo *repository.UserRepository) *UserController {
    return &UserController{userRepo: userRepo}
}

type CreateUserRequest struct {
    Email         string `json:"email"`
    Username      string `json:"username"`
    PasswordHash  string `json:"password_hash"`
}

type CreateUserResponse struct {
    ID       int32  `json:"id"`
    Email    string `json:"email"`
    Username string `json:"username"`
    Status   string `json:"status"`
}

func (c *UserController) CreateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }

    if req.Email == "" || req.Username == "" || req.PasswordHash == "" {
        http.Error(w, "Email, username, and password are required", http.StatusBadRequest)
        return
    }

    // Check if user already exists
    existingUser, err := c.userRepo.GetUserByEmail(ctx, req.Email)
    if err == nil && existingUser != nil {
        http.Error(w, "User already exists", http.StatusConflict)
        return
    }

    user, err := c.userRepo.CreateUser(ctx, req.Email, req.Username, req.PasswordHash)
    if err != nil {
        http.Error(w, "Failed to create user", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(CreateUserResponse{
        ID:       user.ID,
        Email:    user.Email,
        Username: user.Username,
        Status:   string(user.Status),
    })
}

func (c *UserController) GetUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    idStr := r.URL.Path[len("/users/"):]
    id, err := strconv.ParseInt(idStr, 10, 32)
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }

    user, err := c.userRepo.GetUserByID(ctx, int32(id))
    if err != nil {
        if err == repository.ErrUserNotFound {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        http.Error(w, "Failed to get user", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

func (c *UserController) ListUsers(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    users, err := c.userRepo.ListUsers(ctx)
    if err != nil {
        http.Error(w, "Failed to list users", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(users)
}

func (c *UserController) UpdateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    idStr := r.URL.Path[len("/users/"):]
    id, err := strconv.ParseInt(idStr, 10, 32)
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }

    var req struct {
        Email    string `json:"email"`
        Username string `json:"username"`
        Status   string `json:"status"`
    }

    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }

    user, err := c.userRepo.UpdateUser(ctx, int32(id), req.Email, req.Username, db.UserStatus(req.Status))
    if err != nil {
        if err == repository.ErrUserNotFound {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        http.Error(w, "Failed to update user", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

func (c *UserController) DeleteUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    idStr := r.URL.Path[len("/users/"):]
    id, err := strconv.ParseInt(idStr, 10, 32)
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }

    err = c.userRepo.DeleteUser(ctx, int32(id))
    if err != nil {
        if err == repository.ErrUserNotFound {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        http.Error(w, "Failed to delete user", http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusNoContent)
}
```

**main.go**
```go
package main

import (
    "database/sql"
    "log"
    "net/http"
    "os"

    _ "github.com/lib/pq"
    "myproject/internal/controller"
    "myproject/internal/repository"
    "myproject/internal/db"
)

func main() {
    // Connect to database
    dsn := os.Getenv("DATABASE_URL")
    if dsn == "" {
        dsn = "postgres://user:password@localhost:5432/mydb?sslmode=disable"
    }

    dbConn, err := sql.Open("postgres", dsn)
    if err != nil {
        log.Fatal(err)
    }
    defer dbConn.Close()

    // Test connection
    if err := dbConn.Ping(); err != nil {
        log.Fatal(err)
    }

    // Initialize sqlc queries
    queries := db.New(dbConn)

    // Initialize repositories
    userRepo := repository.NewUserRepository(queries)

    // Initialize controllers
    userController := controller.NewUserController(userRepo)

    // Setup routes
    mux := http.NewServeMux()

    mux.HandleFunc("GET /users", userController.ListUsers)
    mux.HandleFunc("GET /users/{id}", userController.GetUser)
    mux.HandleFunc("POST /users", userController.CreateUser)
    mux.HandleFunc("PUT /users/{id}", userController.UpdateUser)
    mux.HandleFunc("DELETE /users/{id}", userController.DeleteUser)

    // Start server
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Server starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, mux))
}
```

## 7. Error Handling Patterns with sqlc

### Custom Error Types

```go
package errors

import (
    "errors"
    "fmt"
)

var (
    // User errors
    ErrUserNotFound      = errors.New("user not found")
    ErrUserExists        = errors.New("user already exists")
    ErrInvalidEmail      = errors.New("invalid email format")
    ErrInvalidPassword   = errors.New("invalid password")
    ErrUserInactive      = errors.New("user is inactive")

    // Post errors
    ErrPostNotFound      = errors.New("post not found")
    ErrPostExists        = errors.New("post already exists")
    ErrInvalidPostTitle  = errors.New("invalid post title")
)

// Wrap errors with context
func WrapUserNotFound(id int32) error {
    return fmt.Errorf("user with id %d not found: %w", id, ErrUserNotFound)
}

// Check if error is user not found
func IsUserNotFound(err error) bool {
    return errors.Is(err, ErrUserNotFound)
}
```

### Error Handling in Repository

```go
func (r *UserRepository) CreateUser(ctx context.Context, email, username, passwordHash string) (*db.User, error) {
    user, err := r.q.CreateUser(ctx, db.CreateUserParams{
        Email:         email,
        Username:      username,
        PasswordHash:  passwordHash,
    })
    if err != nil {
        // Handle unique constraint violations
        if strings.Contains(err.Error(), "duplicate key value violates unique constraint") {
            return nil, ErrUserExists
        }
        return nil, fmt.Errorf("failed to create user: %w", err)
    }
    return &user, nil
}
```

### Error Handling in Controller

```go
func (c *UserController) CreateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }

    // Validate input
    if !isValidEmail(req.Email) {
        http.Error(w, "Invalid email format", http.StatusBadRequest)
        return
    }

    // Create user
    user, err := c.userService.CreateUser(ctx, req.Email, req.Username, req.PasswordHash)
    if err != nil {
        if errors.Is(err, errors.ErrUserExists) {
            http.Error(w, "User already exists", http.StatusConflict)
            return
        }
        if errors.Is(err, errors.ErrInvalidEmail) {
            http.Error(w, "Invalid email format", http.StatusBadRequest)
            return
        }
        http.Error(w, "Failed to create user", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(user)
}
```

### Error Handling with sqlc

```go
// Handle sql.ErrNoRows
user, err := r.q.GetUser(ctx, id)
if err != nil {
    if errors.Is(err, sql.ErrNoRows) {
        return nil, ErrUserNotFound
    }
    return nil, fmt.Errorf("failed to get user: %w", err)
}

// Handle constraint violations
user, err := r.q.CreateUser(ctx, params)
if err != nil {
    if strings.Contains(err.Error(), "duplicate key value violates unique constraint") {
        return nil, ErrUserExists
    }
    return nil, fmt.Errorf("failed to create user: %w", err)
}

// Handle transaction errors
tx, err := db.BeginTx(ctx, nil)
if err != nil {
    return nil, fmt.Errorf("failed to begin transaction: %w", err)
}
defer tx.Rollback()

// ... operations ...

if err := tx.Commit(); err != nil {
    return nil, fmt.Errorf("failed to commit transaction: %w", err)
}
```

## 8. Testing Strategies with sqlc-Generated Code

### Unit Tests for Repository

```go
package repository_test

import (
    "context"
    "testing"
    "time"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "myproject/internal/db"
    "myproject/internal/repository"
)

func setupTestDB(t *testing.T) *db.Queries {
    // Create test database connection
    dsn := "postgres://user:password@localhost:5432/testdb?sslmode=disable"
    dbConn, err := sql.Open("postgres", dsn)
    require.NoError(t, err)

    // Run migrations
    // ...

    return db.New(dbConn)
}

func TestUserRepository_CreateUser(t *testing.T) {
    ctx := context.Background()
    queries := setupTestDB(t)
    repo := repository.NewUserRepository(queries)

    user, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
    require.NoError(t, err)
    assert.NotNil(t, user)
    assert.Equal(t, "test@example.com", user.Email)
    assert.Equal(t, "testuser", user.Username)
    assert.Equal(t, db.UserStatusActive, user.Status)
}

func TestUserRepository_GetUserByID(t *testing.T) {
    ctx := context.Background()
    queries := setupTestDB(t)
    repo := repository.NewUserRepository(queries)

    // Create test user
    user, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
    require.NoError(t, err)

    // Get user by ID
    retrievedUser, err := repo.GetUserByID(ctx, user.ID)
    require.NoError(t, err)
    assert.Equal(t, user.ID, retrievedUser.ID)
    assert.Equal(t, user.Email, retrievedUser.Email)
    assert.Equal(t, user.Username, retrievedUser.Username)
}

func TestUserRepository_GetUserByEmail(t *testing.T) {
    ctx := context.Background()
    queries := setupTestDB(t)
    repo := repository.NewUserRepository(queries)

    // Create test user
    _, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
    require.NoError(t, err)

    // Get user by email
    retrievedUser, err := repo.GetUserByEmail(ctx, "test@example.com")
    require.NoError(t, err)
    assert.Equal(t, "test@example.com", retrievedUser.Email)
    assert.Equal(t, "testuser", retrievedUser.Username)
}

func TestUserRepository_UpdateUser(t *testing.T) {
    ctx := context.Background()
    queries := setupTestDB(t)
    repo := repository.NewUserRepository(queries)

    // Create test user
    user, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
    require.NoError(t, err)

    // Update user
    updatedUser, err := repo.UpdateUser(ctx, user.ID, "updated@example.com", "updateduser", db.UserStatusInactive)
    require.NoError(t, err)
    assert.Equal(t, "updated@example.com", updatedUser.Email)
    assert.Equal(t, "updateduser", updatedUser.Username)
    assert.Equal(t, db.UserStatusInactive, updatedUser.Status)
}

func TestUserRepository_DeleteUser(t *testing.T) {
    ctx := context.Background()
    queries := setupTestDB(t)
    repo := repository.NewUserRepository(queries)

    // Create test user
    user, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
    require.NoError(t, err)

    // Delete user
    err = repo.DeleteUser(ctx, user.ID)
    require.NoError(t, err)

    // Verify user is deleted
    _, err = repo.GetUserByID(ctx, user.ID)
    assert.Error(t, err)
    assert.True(t, errors.Is(err, repository.ErrUserNotFound))
}
```

### Integration Tests

```go
package integration_test

import (
    "context"
    "database/sql"
    "testing"
    "time"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "myproject/internal/db"
    "myproject/internal/repository"
)

func TestUserRepositoryIntegration(t *testing.T) {
    // Use test database
    dsn := "postgres://user:password@localhost:5432/integration_test?sslmode=disable"
    dbConn, err := sql.Open("postgres", dsn)
    require.NoError(t, err)
    defer dbConn.Close()

    // Run migrations
    // ...

    ctx := context.Background()
    queries := db.New(dbConn)
    repo := repository.NewUserRepository(queries)

    // Test full user lifecycle
    t.Run("CreateUser", func(t *testing.T) {
        user, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
        require.NoError(t, err)
        assert.NotNil(t, user)
    })

    t.Run("GetUserByID", func(t *testing.T) {
        // Create user first
        user, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
        require.NoError(t, err)

        // Get user
        retrievedUser, err := repo.GetUserByID(ctx, user.ID)
        require.NoError(t, err)
        assert.Equal(t, user.ID, retrievedUser.ID)
    })

    t.Run("UpdateUser", func(t *testing.T) {
        // Create user first
        user, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
        require.NoError(t, err)

        // Update user
        updatedUser, err := repo.UpdateUser(ctx, user.ID, "updated@example.com", "updateduser", db.UserStatusInactive)
        require.NoError(t, err)
        assert.Equal(t, "updated@example.com", updatedUser.Email)
    })

    t.Run("DeleteUser", func(t *testing.T) {
        // Create user first
        user, err := repo.CreateUser(ctx, "test@example.com", "testuser", "hashedpassword")
        require.NoError(t, err)

        // Delete user
        err = repo.DeleteUser(ctx, user.ID)
        require.NoError(t, err)

        // Verify user is deleted
        _, err = repo.GetUserByID(ctx, user.ID)
        assert.Error(t, err)
    })
}
```

### Test Database Setup

**Makefile**
```makefile
.PHONY: test test-unit test-integration test-coverage

test:
	go test -v ./...

test-unit:
	go test -v -short ./...

test-integration:
	go test -v -tags=integration ./...

test-coverage:
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
```

**go.mod**
```go
module myproject

go 1.21

require (
    github.com/lib/pq v1.10.9
    github.com/stretchr/testify v1.8.4
)

require (
    github.com/jackc/pgpassfile v1.0.0 // indirect
    github.com/jackc/pgservicefile v0.0.0-20221227161230-091c0ba34f0a // indirect
    github.com/jackc/pgx/v5 v5.4.3 // indirect
    github.com/jackc/tern v2.1.0+incompatible // indirect
    github.com/mattn/go-sqlite3 v1.14.18 // indirect
    github.com/onsi/ginkgo/v2 v2.9.5 // indirect
    github.com/onsi/gomega v1.27.8 // indirect
    github.com/twitchyliquid64/golang-asm v0.15.1 // indirect
    golang.org/x/arch v0.3.0 // indirect
    golang.org/x/crypto v0.14.0 // indirect
    golang.org/x/net v0.17.0 // indirect
    golang.org/x/sys v0.13.0 // indirect
    golang.org/x/tools v0.13.0 // indirect
    gopkg.in/yaml.v3 v3.0.1 // indirect
)
```

### Test Configuration

**.env.test**
```env
DATABASE_URL=postgres://user:password@localhost:5432/testdb?sslmode=disable
PORT=8081
```

**go test -tags=integration**
```go
//go:build integration

package integration_test

import (
    "testing"
)

func TestIntegration(t *testing.T) {
    // Integration tests
}
```

## Summary

sqlc provides a powerful way to generate type-safe database access code from SQL queries. By following the patterns and best practices outlined in this guide, you can:

1. **Set up sqlc** with proper configuration
2. **Define database models** using SQL DDL
3. **Generate Go code** from SQL queries
4. **Implement repository pattern** for data access
5. **Create controllers** for HTTP handling
6. **Handle errors** properly with custom error types
7. **Write comprehensive tests** for your code

The key benefits of using sqlc are:
- **Type safety**: Compile-time checking of SQL queries
- **Better developer experience**: No manual mapping between SQL and Go
- **Fewer runtime errors**: sqlc catches SQL errors at compile time
- **Clean code**: Generated code is idiomatic and maintainable
- **Performance**: Prepared statements and optimized queries

By following the structure and patterns in this guide, you can build robust, maintainable applications with PostgreSQL and Go using sqlc.
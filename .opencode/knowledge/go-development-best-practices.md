# Go (Golang) Development Best Practices

## Table of Contents
1. [Project Structure Best Practices](#project-structure-best-practices)
2. [Common Tools and Frameworks](#common-tools-and-frameworks)
3. [Code Organization Best Practices](#code-organization-best-practices)
4. [Testing and Documentation Standards](#testing-and-documentation-standards)
5. [Build Tools and Package Managers](#build-tools-and-package-managers)
6. [Common Pitfalls and Anti-Patterns](#common-pitfalls-and-anti-patterns)

---

## Project Structure Best Practices

### Standard Go Project Layout

The standard Go project layout follows a specific directory structure that promotes clarity and maintainability:

```
project-root/
├── cmd/                    # Main applications
│   └── myapp/             # Executable name matches directory
│       └── main.go
├── internal/               # Private application and library code
│   ├── app/               # Application-specific code
│   └── pkg/               # Shared internal code
├── pkg/                    # Library code for external use
│   └── mypubliclib/
├── api/                    # OpenAPI/Swagger specs, JSON schemas
├── configs/                # Configuration file templates
├── docs/                   # Design and user documents
├── examples/               # Examples for applications/libraries
├── scripts/                # Build, install, analysis scripts
├── build/                  # Packaging and CI configurations
│   ├── ci/                # CI tool configs (Travis, Circle, etc.)
│   └── package/           # Package configs (Docker, AMI, etc.)
├── deployments/            # Deployment configurations
├── test/                   # Additional test apps and data
├── tools/                  # Supporting tools for the project
├── third_party/            # External helper tools and utilities
├── web/                    # Web app components (static assets, templates)
├── assets/                 # Other project assets (images, logos)
├── website/                # Project website data
├── githooks/               # Git hooks
├── vendor/                 # Application dependencies
├── go.mod                  # Module definition
├── go.sum                  # Dependency checksums
├── Makefile                # Build automation
├── .gitignore              # Git ignore patterns
├── .editorconfig           # Editor configuration
└── README.md               # Project documentation
```

### Key Directory Guidelines

#### `/cmd`
- Contains main applications
- Directory name should match the executable name
- Keep code minimal - use `internal` or `pkg` for reusable code
- Main package should be `package main`

#### `/internal`
- Private packages that cannot be imported by external projects
- Enforced by Go compiler (Go 1.4+)
- Can have subdirectories for better organization
- Use for code that shouldn't be reused by others

#### `/pkg`
- Library code intended for external use
- Other projects can import these libraries
- Use when you want to explicitly communicate that code is safe for external use
- Avoid meaningless names like `util`, `common`, `misc`, `api`, `types`

#### `/vendor`
- Application dependencies managed manually or by Go Modules
- Created with `go mod vendor`
- Don't commit dependencies if building a library

---

## Common Tools and Frameworks

### Core Go Tools

#### Code Formatting
- **gofmt**: Automatically formats Go code according to standard style
  ```bash
  gofmt -w .
  ```
- **goimports**: Superset of gofmt that also manages import statements
  ```bash
  goimports -w .
  ```

#### Code Quality
- **staticcheck**: Advanced linter (replaces deprecated golint)
  ```bash
  staticcheck ./...
  ```
- **golint**: Deprecated - use staticcheck instead
- **gocyclo**: Checks for high cyclomatic complexity
- **ineffassign**: Detects ineffectual assignments
- **misspell**: Finds misspelled words

#### Testing
- **go test**: Built-in testing framework
  ```bash
  go test ./...
  go test -v ./...
  go test -cover ./...
  ```
- **testify**: Assertion library for tests
- **gomock**: Mocking framework
- **testcontainers**: Integration testing with Docker containers

#### Documentation
- **godoc**: Generates documentation from code comments
  ```bash
  godoc -http=:6060
  ```
- **pkg.go.dev**: Online documentation for Go packages

### Popular Frameworks

#### Web Frameworks
- **Gin**: High-performance HTTP framework
- **Echo**: Expressive and fast Go web framework
- **Fiber**: Express inspired Go web framework
- **Chi**: Lightweight router for Go

#### Database
- **GORM**: ORM for Go
- **sqlx**: Extensions for database/sql
- **pgx**: PostgreSQL driver and toolkit
- **mongo-go-driver**: MongoDB driver

#### Microservices
- **gRPC**: Google's RPC framework
- **gRPC-Gateway**: gRPC to JSON conversion
- **Consul**: Service discovery and configuration
- **Etcd**: Distributed key-value store

#### Configuration
- **Viper**: Complete configuration solution
- **Env**: Environment variable parsing
- **Zap**: Structured logging

#### Utilities
- **cobra**: CLI framework
- **urfave/cli**: Simple, fast, and fun CLI
- **go-redis**: Redis client
- **prometheus/client_golang**: Prometheus metrics

---

## Code Organization Best Practices

### Package Naming Conventions

1. **Package names should be:**
   - Short, concise, and evocative
   - Lowercase (no underscores or mixedCaps)
   - Based on the directory name
   - Avoid generic names like `util`, `common`, `api`

2. **Example:**
   ```go
   // Good
   package httpclient

   // Bad
   package HTTPClient
   package http_client
   package util
   ```

### Naming Conventions

#### Exported vs Unexported Names
- **Exported** (capitalized): Visible outside the package
- **Unexported** (lowercase): Visible only within the package

#### Function Names
- Use verbs for functions: `GetUser`, `CreateOrder`
- Don't use `Get` prefix for getters (Go doesn't require it)
- Use `Set` prefix for setters

#### Interface Names
- One-method interfaces should end with `-er` suffix
- Examples: `Reader`, `Writer`, `Formatter`, `Closer`

#### MixedCaps
- Use `MixedCaps` or `mixedCaps` for multiword names
- Never use underscores
- Example: `userID`, `httpRequest`, `xmlHTTPRequest`

#### Initialisms
- Initialisms like `URL`, `NATO`, `ID` should have consistent case
- Example: `URL` or `url`, never `Url`
- Example: `appID`, never `appId`

### Code Structure

#### Functions
- Prefer synchronous functions over asynchronous
- Keep functions focused and small
- Use multiple return values for error handling
- Use named return parameters sparingly (only for clarity)

#### Error Handling
- Always check errors
- Don't discard errors with `_`
- Use `fmt.Errorf` for error formatting
- Error strings should not be capitalized (unless proper nouns)

```go
// Good
if err != nil {
    return fmt.Errorf("failed to create user: %w", err)
}

// Bad
if err != nil {
    return err
}
```

#### Context Usage
- Pass `context.Context` as first parameter
- Use `context.Background()` only when appropriate
- Don't add Context as a struct member
- Don't create custom Context types

```go
// Good
func ProcessData(ctx context.Context, data []byte) error {
    // ...
}

// Bad
type Service struct {
    ctx context.Context  // Don't do this
}
```

#### Goroutine Management
- Make goroutine lifetimes clear
- Avoid goroutine leaks
- Document when goroutines exit
- Use channels for communication

### Control Structures

#### If Statements
- Always use braces
- Put error handling first
- Use short variable declarations in if statements

```go
// Good
if err := file.Read(); err != nil {
    return err
}
// normal code

// Bad
if err != nil {
    return err
} else {
    // normal code
}
```

#### For Loops
- Three forms: `for init; condition; post`, `for condition`, `for {}`
- Use `range` for slices, maps, channels
- Use blank identifier `_` when you don't need all values

```go
// Good
for i, v := range slice {
    // use i and v
}

// Good
for _, v := range slice {
    // use only v
}
```

#### Switch Statements
- Can switch on any type
- No automatic fallthrough
- Can have comma-separated cases
- Can switch without expression (switches on true)

---

## Testing and Documentation Standards

### Testing

#### Unit Testing
- Test files must end with `_test.go`
- Test functions must start with `Test`
- Use `testing.T` for test reporting

```go
func TestHelloName(t *testing.T) {
    name := "Gladys"
    msg, err := Hello(name)
    if err != nil {
        t.Errorf("Hello(%q) failed: %v", name, err)
    }
    if msg == "" {
        t.Errorf("Hello(%q) returned empty string", name)
    }
}
```

#### Table-Driven Tests
- Use for testing multiple input/output combinations
- Improves test readability and maintainability

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 1, 2, 3},
        {"negative numbers", -1, -2, -3},
        {"zero", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

#### Testing Best Practices
- Write tests that fail with helpful messages
- Test both success and failure cases
- Use `t.Run()` for subtests
- Test edge cases and boundary conditions
- Keep tests independent

#### Benchmarking
- Benchmark functions start with `Benchmark`
- Use `go test -bench=.` to run benchmarks
- Measure performance improvements

```go
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(1, 2)
    }
}
```

### Documentation

#### Doc Comments
- All exported names should have doc comments
- Comments should be full sentences
- Start with the name being documented
- End with a period
- Use `//` for line comments

```go
// Package httpclient provides HTTP client functionality.
package httpclient

// Request represents an HTTP request.
type Request struct {
    URL    string
    Method string
}

// Do executes the request and returns the response.
func (r *Request) Do() (*Response, error) {
    // ...
}
```

#### Package Comments
- Must appear adjacent to the package clause
- No blank line between package comment and package declaration
- For `package main`, use "Binary", "Command", or "Program" prefix

```go
// Package math provides basic constants and mathematical functions.
package math

// Binary myapp is a command-line tool for processing data.
package main
```

#### Example Functions
- Include runnable examples in your package
- Use `Example` prefix for example functions
- Go automatically generates documentation from examples

```go
// ExampleHello demonstrates the Hello function.
func ExampleHello() {
    fmt.Println(Hello("World"))
    // Output: Hello, World!
}
```

---

## Build Tools and Package Managers

### Go Modules

#### Module Initialization
```bash
# Initialize a new module
go mod init example.com/myproject

# Initialize with a specific Go version
go mod init example.com/myproject v1.16
```

#### Managing Dependencies
```bash
# Download dependencies
go mod download

# Tidy up dependencies (remove unused, add missing)
go mod tidy

# Verify dependencies
go mod verify

# Update dependencies to latest compatible versions
go get -u ./...

# Update to specific version
go get example.com/pkg@v1.2.3
```

#### Module Files
- **go.mod**: Module definition and requirements
- **go.sum**: Dependency checksums for reproducibility

#### Module Path
- Should match the repository URL
- Used for import paths
- Example: `github.com/user/project`

### Build Commands

#### Compilation
```bash
# Build current package
go build

# Build specific package
go build ./pkg

# Build with specific output name
go build -o myapp

# Build for specific platform
go build -o myapp_linux_amd64 ./cmd/myapp
```

#### Installation
```bash
# Install current package to GOPATH/bin
go install

# Install specific package
go install example.com/pkg

# Install with specific output name
go install -o /usr/local/bin/myapp ./cmd/myapp
```

#### Running
```bash
# Compile and run
go run main.go

# Run with arguments
go run main.go arg1 arg2

# Run with environment variables
GO_ENV=production go run main.go
```

#### Testing
```bash
# Run all tests
go test

# Run tests with verbose output
go test -v

# Run tests with coverage
go test -cover

# Run specific test
go test -run TestHello

# Run benchmarks
go test -bench=.

# Run tests with race detector
go test -race

# Run tests with memory sanitizer
go test -msan
```

### Common Build Patterns

#### Build Tags
```go
// +build linux

package main

func main() {
    // Linux-specific code
}
```

#### Build Constraints
```bash
# Build with specific tags
go build -tags=linux,production

# Build without specific tags
go build -tags=-integration
```

#### Cross-Compilation
```bash
# Build for Windows
GOOS=windows GOARCH=amd64 go build

# Build for Linux
GOOS=linux GOARCH=amd64 go build

# Build for multiple platforms
GOOS=linux GOARCH=amd64 go build -o myapp_linux
GOOS=darwin GOARCH=amd64 go build -o myapp_mac
GOOS=windows GOARCH=amd64 go build -o myapp.exe
```

### CI/CD Integration

#### GitHub Actions Example
```yaml
name: Go

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-go@v2
        with:
          go-version: '1.16'
      - run: go test -v ./...
      - run: go build -v ./...
```

#### GitLab CI Example
```yaml
test:
  image: golang:1.16
  script:
    - go test -v ./...
    - go build -v ./...
```

---

## Common Pitfalls and Anti-Patterns

### Code Style Issues

#### 1. Not Using gofmt
- **Problem**: Inconsistent code formatting
- **Solution**: Always run `gofmt` before committing
- **Impact**: Makes code harder to read and maintain

#### 2. Poor Error Handling
- **Problem**: Ignoring errors or using panic for normal errors
- **Solution**: Always check errors, use multiple return values
- **Impact**: Silent failures and hard-to-debug issues

```go
// Bad
result, _ := someFunction()  // Ignore error

// Bad
if err != nil {
    panic(err)  // Don't panic for normal errors
}

// Good
result, err := someFunction()
if err != nil {
    return fmt.Errorf("failed to call someFunction: %w", err)
}
```

#### 3. Inappropriate Use of Pointers
- **Problem**: Passing pointers unnecessarily
- **Solution**: Pass values when appropriate
- **Impact**: Unnecessary indirection and complexity

```go
// Bad
func ProcessString(s *string) {  // Unnecessary pointer
    // ...
}

// Good
func ProcessString(s string) {  // Pass by value
    // ...
}
```

#### 4. Poor Variable Naming
- **Problem**: Long, uninformative variable names
- **Solution**: Use short, descriptive names for local variables
- **Impact**: Harder to read and understand code

```go
// Bad
numberOfUsersInDatabase := 10

// Good
userCount := 10
```

### Architecture Issues

#### 1. Violating Package Boundaries
- **Problem**: Importing packages you shouldn't
- **Solution**: Use `internal` for private code, `pkg` for public libraries
- **Impact**: Tight coupling and reduced maintainability

#### 2. Overusing Interfaces
- **Problem**: Creating interfaces without real usage
- **Solution**: Define interfaces where they're actually needed
- **Impact**: Unnecessary abstraction and complexity

#### 3. Circular Dependencies
- **Problem**: Packages importing each other
- **Solution**: Refactor to break the cycle
- **Impact**: Build failures and hard-to-understand dependencies

#### 4. Global State
- **Problem**: Using global variables
- **Solution**: Pass dependencies explicitly
- **Impact**: Hard to test and reason about

```go
// Bad
var globalConfig Config

// Good
type Service struct {
    config Config
}

func NewService(config Config) *Service {
    return &Service{config: config}
}
```

### Concurrency Issues

#### 1. Goroutine Leaks
- **Problem**: Goroutines that never exit
- **Solution**: Use channels properly, document goroutine lifetimes
- **Impact**: Memory leaks and resource exhaustion

#### 2. Race Conditions
- **Problem**: Concurrent access to shared state
- **Solution**: Use proper synchronization (mutexes, channels)
- **Impact**: Data corruption and unpredictable behavior

```go
// Bad (race condition)
var counter int

func increment() {
    counter++  // Not thread-safe
}

// Good
var counter int
var mu sync.Mutex

func increment() {
    mu.Lock()
    counter++
    mu.Unlock()
}
```

#### 3. Improper Channel Usage
- **Problem**: Closing channels incorrectly
- **Solution**: Use `defer` for cleanup, follow channel patterns
- **Impact**: Panics and resource leaks

### Testing Issues

#### 1. Insufficient Test Coverage
- **Problem**: Not testing edge cases and error paths
- **Solution**: Write comprehensive tests
- **Impact**: Hidden bugs in production

#### 2. Poor Test Messages
- **Problem**: Tests fail without clear information
- **Solution**: Use descriptive error messages
- **Impact**: Hard to debug failing tests

```go
// Bad
if got != want {
    t.Errorf("Test failed")
}

// Good
if got != want {
    t.Errorf("Add(%d, %d) = %d; want %d",
        a, b, got, want)
}
```

#### 3. Test Dependencies
- **Problem**: Tests that depend on external services
- **Solution**: Use mocks and testcontainers
- **Impact**: Slow tests and flaky tests

### Documentation Issues

#### 1. Missing Doc Comments
- **Problem**: No documentation for exported functions/types
- **Solution**: Add doc comments to all exported names
- **Impact**: Hard to understand and use the code

#### 2. Incomplete Examples
- **Problem**: No runnable examples
- **Solution**: Add Example functions
- **Impact**: Hard to understand usage

### Performance Issues

#### 1. Inefficient String Concatenation
- **Problem**: Using `+` in loops for strings
- **Solution**: Use `strings.Builder` or `fmt.Sprintf`
- **Impact**: Poor performance

```go
// Bad
var result string
for _, s := range strings {
    result += s  // Creates new string each iteration
}

// Good
var builder strings.Builder
for _, s := range strings {
    builder.WriteString(s)
}
result := builder.String()
```

#### 2. Unnecessary Allocations
- **Problem**: Creating unnecessary slices/maps
- **Solution**: Reuse objects when possible
- **Impact**: Increased memory usage and GC pressure

### Security Issues

#### 1. Using Weak Random Number Generation
- **Problem**: Using `math/rand` for security
- **Solution**: Use `crypto/rand`
- **Impact**: Predictable values, security vulnerabilities

```go
// Bad
rand.Seed(time.Now().UnixNano())
randomValue := rand.Intn(100)

// Good
randomValue := rand.Intn(100)
```

#### 2. Not Validating Input
- **Problem**: Trusting all input without validation
- **Solution**: Validate and sanitize all inputs
- **Impact**: Security vulnerabilities

### Best Practices Summary

#### Do's
- ✅ Use `gofmt` for code formatting
- ✅ Always check errors
- ✅ Use `context.Context` for request-scoped values
- ✅ Write comprehensive tests
- ✅ Add doc comments to exported names
- ✅ Use `go mod` for dependency management
- ✅ Keep functions small and focused
- ✅ Use interfaces judiciously
- ✅ Document goroutine lifetimes
- ✅ Use `defer` for resource cleanup

#### Don'ts
- ❌ Ignore errors
- ❌ Use panic for normal errors
- ❌ Create unnecessary pointers
- ❌ Use global variables
- ❌ Violate package boundaries
- ❌ Create circular dependencies
- ❌ Use `math/rand` for security
- ❌ Ignore test failures
- ❌ Skip documentation
- ❌ Use `+` for string concatenation in loops

---

## Additional Resources

### Official Documentation
- [Go Documentation](https://go.dev/doc/)
- [Effective Go](https://go.dev/doc/effective_go)
- [How to Write Go Code](https://go.dev/doc/code)
- [Go Modules](https://go.dev/doc/modules)

### Community Resources
- [Go Wiki](https://go.dev/wiki/)
- [Go Blog](https://blog.golang.org/)
- [Go Forum](https://forum.golangbridge.org/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/go)

### Tools and Linters
- [gofmt](https://pkg.go.dev/cmd/gofmt)
- [staticcheck](https://staticcheck.io/)
- [golint](https://github.com/golang/lint) (deprecated)
- [gocyclo](https://github.com/fzipp/gocyclo)
- [go vet](https://pkg.go.dev/cmd/go#hdr-Go_vet)

### Learning Resources
- [A Tour of Go](https://go.dev/tour/)
- [Go by Example](https://gobyexample.com/)
- [Awesome Go](https://awesome-go.com/)

---

*Last Updated: May 28, 2026*
*Version: 1.0*
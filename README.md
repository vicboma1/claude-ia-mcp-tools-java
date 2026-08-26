# MCP Users Server (Java)

MCP server for user management with clean separation of concerns: API client layer, business logic, and MCP tool handlers.

## Architecture

```
src/main/java/com/example/
├── api/
│   └── ApiClient.java        // HTTP client (no business logic)
├── business/
│   └── UserService.java      // Business layer (reusable)
├── mcp/
│   ├── McpServer.java        // MCP protocol handler
│   └── ToolRegistry.java     // Tool definitions
```

## Tools Exposed

1. `get_user` - Get one user by ID
2. `list_users` - List all users
3. `create_user` - Create a new user
4. `update_user` - Update user name/email
5. `delete_user` - Delete a user

## Requirements

- Java 11+
- Maven 3.6+

## Setup

```bash
mvn clean install
```

## Run the MCP Server

```bash
mvn exec:java -Dexec.mainClass="com.example.mcp.McpServer"
```

Or after building:

```bash
java -cp target/mcp-users-server-1.0.0.jar com.example.mcp.McpServer
```

Or native:

```java
java -jar target/mcp-users-server-*.jar
```

## Run Tests

```bash
mvn test
```

Or after run

```bash
bash test-local.sh
```


## MCP Configuration

### Via stdio (Claude Desktop)

```json
{
  "mcpServers": {
    "example-users": {
      "command": "java",
      "args": ["-cp", "path/to/mcp-users-server-1.0.0.jar", "com.example.mcp.McpServer"]
    }
  }
}
```

### Test via command line

```bash
echo '{"jsonrpc":"2.0","method":"initialize","id":1}' | java -cp target/mcp-users-server-1.0.0.jar com.example.mcp.McpServer
echo '{"jsonrpc":"2.0","method":"tools/list","id":2}' | java -cp target/mcp-users-server-1.0.0.jar com.example.mcp.McpServer
```

## Implementation Notes

- **ApiClient**: HTTP-only, no business decisions. Uses OkHttp for resilient connections with timeouts.
- **UserService**: Business logic layer. Validates inputs, normalizes data, handles edge cases. Reusable by tests, batch jobs, REST endpoints, etc.
- **McpServer**: Thin layer that validates MCP inputs and delegates to UserService.

This architecture ensures the business logic is completely decoupled from the MCP transport layer, making it testable and reusable.

## Test Coverage

- 5+ test cases for each tool
- Edge cases: empty strings, invalid emails, zero/negative IDs
- Mock API client for unit testing
- Both service and server layer tests

Run with coverage:

```bash
mvn test jacoco:report
open target/site/jacoco/index.html
```

## Dependencies

- **OkHttp 4.11.0** - HTTP client
- **Gson 2.10.1** - JSON serialization
- **SLF4J + Logback** - Logging
- **JUnit 5** - Testing
- **Mockito 5.3.1** - Mocking

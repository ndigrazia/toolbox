# Model Context Protocol (MCP) Database Toolbox with PostgreSQL

This repository provides a containerized development environment combining a PostgreSQL database instance with the Model Context Protocol (MCP) Database Toolbox. The system features a custom secure `Dockerfile` running as a non-root user, a fully-configured `docker-compose.yml`, schema initialization (`init.sql`), and defined database tools (`tools.yaml`).

For more details on the Model Context Protocol and available tools, visit the [Model Context Protocol (MCP) Toolbox Website](https://mcp-toolbox.dev/) or the [Google Cloud MCP Toolbox Repository](https://github.com/googleapis/mcp-toolbox).

---

## 🏗️ Architecture & Services

The stack is defined in `docker-compose.yml` and consists of two primary services:

1. **`postgres` (PostgreSQL Database)**:
   - Uses the robust, lightweight `postgres:16-alpine` image.
   - Forwards database port `5432` to the host system.
   - Automatically bootstraps roles, databases, and schema configurations on startup using `init.sql`.
   - Persists all database data locally through a Docker volume (`pgdata1`).

2. **`toolbox` (MCP Database Toolbox Server)**:
   - Built locally from our secure `Dockerfile` (extending the official `us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest` distroless image).
   - Runs in `network_mode: "host"`, giving it zero-latency localhost access to the `postgres` database container.
   - Operates securely under the non-root user `nobody` (UID `65534`).
   - Copies and monitors the `tools.yaml` configuration file.
   - Deploys the MCP server on port `5000` (configurable).

---

## 🔑 Database Credentials & Access

### 📡 Connection Details
- **Host**: `127.0.0.1` (or `localhost`)
- **Port**: `5432`

### 👤 Roles & Databases
- **Default Superuser**: `postgres` (password: `123456`)
- **Application User**: `toolbox_client` (password: `my-password`)
- **Application Database**: `toolbox_db`

---

## 📜 Schema & Seeding Data (`init.sql`)

The database is initialized automatically on first startup via `init.sql`. The initialization creates the application schema and seeds a `hotels` table with initial test data.

### Database Table: `hotels`
| Column Name | Data Type | Modifiers | Description |
| :--- | :--- | :--- | :--- |
| **`id`** | `VARCHAR(255)` | `PRIMARY KEY` | Unique ID of the hotel. |
| **`name`** | `VARCHAR(255)` | `NOT NULL` | Name of the hotel. |
| **`location`** | `VARCHAR(255)` | `NOT NULL` | City/Location of the hotel. |
| **`booked`** | `BIT(1)` | `DEFAULT B'0'` | Booking status (0 = Available, 1 = Booked). |
| **`checkin_date`** | `DATE` | `NULL` | Check-in date. |
| **`checkout_date`** | `DATE` | `NULL` | Check-out date. |

### Seeded Records
Four pre-populated hotels are seeded into the database:
1. `Grand Plaza Hotel` in `New York`
2. `Seaside Resort` in `Miami`
3. `Mountain Lodge` in `Denver`
4. `Central Park Suites` in `New York`

---

## 🛠️ MCP Tool Definitions (`tools.yaml`)

The toolbox service exposes **5 PostgreSQL-backed MCP tools** connected to the `my-pg-source` source. These can be executed by any MCP-compliant client or agent:

1. **`search-hotels-by-name`**
   - *Description*: Searches for hotels matching a substring of the name.
   - *Parameters*: `name` (string)
   - *SQL*: `SELECT * FROM hotels WHERE name ILIKE '%' || $1 || '%';`

2. **`search-hotels-by-location`**
   - *Description*: Searches for hotels matching a location.
   - *Parameters*: `location` (string)
   - *SQL*: `SELECT * FROM hotels WHERE location ILIKE '%' || $1 || '%';`

3. **`book-hotel`**
   - *Description*: Books a hotel by ID. Returns `NULL` on success or raises an error on failure.
   - *Parameters*: `hotel_id` (string)
   - *SQL*: `UPDATE hotels SET booked = B'1' WHERE id = $1;`

4. **`update-hotel`**
   - *Description*: Updates check-in and check-out dates for a hotel booking.
   - *Parameters*: `hotel_id` (string), `checkin_date` (string), `checkout_date` (string)
   - *SQL*: `UPDATE hotels SET checkin_date = CAST($2 as date), checkout_date = CAST($3 as date) WHERE id = $1;`

5. **`cancel-hotel`**
   - *Description*: Cancels a booking for a hotel.
   - *Parameters*: `hotel_id` (string)
   - *SQL*: `UPDATE hotels SET booked = B'0' WHERE id = $1;`

---

## 🚀 Step-by-Step Usage Instructions

### 1. Stop Conflicts (Prerequisites)
Make sure port `5432` is free. If you have local PostgreSQL running, stop it:
```bash
sudo systemctl stop postgresql
```

### 2. Launch the Stack
Start both services in detached mode (use `--build` to compile the local Dockerfile):
```bash
docker-compose down -v && docker-compose up -d --build
```
*Note: The `-v` flag deletes previous volumes, ensuring a completely clean initialization of the seed data.*

### 3. Verify Container Logs
Check the PostgreSQL container logs to ensure that the startup and schema seed completed successfully:
```bash
docker logs postgres
```

Check the Toolbox container logs to confirm the server is serving on port 5000:
```bash
docker logs toolbox_toolbox_1
```

### 4. Query Database Directly
Verify that database connections and seed data are correct using `psql` within the database container:
```bash
PGPASSWORD=my-password docker exec -it postgres psql -U toolbox_client -d toolbox_db -c "SELECT * FROM hotels;"
```

### 5. Test using the MCP Inspector
To test and interact with the 5 exposed MCP tools, launch the web-based **MCP Inspector** using the Server-Sent Events (SSE) transport endpoint:

- **SSE Transport Endpoint URL**: `http://127.0.0.1:5000/mcp/sse`

```bash
npx @modelcontextprotocol/inspector http://127.0.0.1:5000/mcp/sse
```
This opens a local browser interface where you can dynamically test all SQL tools and examine real-time results returned directly from the PostgreSQL instance!

---

## 🐳 Custom Dockerfile & Image Customization

A `Dockerfile` is provided to build custom self-contained MCP Database Toolbox containers. The container is configured with optimal security and configuration capabilities.

### Key Security & Configuration Features
- **Distroless Base Image**: Minimal attack surface, zero extraneous binaries.
- **Non-Root Execution**: Runs under the unprivileged user `nobody` (UID `65534`).
- **Flexible Configuration Options**:
  - `PORT` environment variable (defaults to `5000`).
  - `CONFIG_PATH` environment variable (defaults to `/app/tools.yaml`).
  - `TOOLS_FILE` build-time argument (defaults to `tools.yaml`).

### Build-time Customization
You can package an external configuration file during image build by passing the `TOOLS_FILE` build-arg:
```bash
docker build --build-arg TOOLS_FILE="path/to/external-tools.yaml" -t custom-mcp-toolbox .
```

### Runtime Customization
You can customize the port or override the configuration path dynamically at runtime using environment variables:
```bash
docker run -d --name mcp-toolbox \
  --network="host" \
  -e PORT=8080 \
  -e CONFIG_PATH=/config/my-tools.yaml \
  -v /absolute/path/to/my-tools.yaml:/config/my-tools.yaml \
  custom-mcp-toolbox
```

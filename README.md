# Model Context Protocol (MCP) Database Toolbox with PostgreSQL

This repository contains a fully configured containerized development environment combining a PostgreSQL database with an MCP Database Toolbox. For more information on Model Context Protocol and available tools, visit the official [Model Context Protocol (MCP) Toolbox Website](https://mcp-toolbox.dev/) or the [Google Cloud MCP Toolbox Repository](https://github.com/googleapis/mcp-toolbox).

---

## 🏗️ Architecture & Component Overview

The system is defined inside `docker-compose.yml` and consists of two primary services:

1. **`postgres` (PostgreSQL Database)**:
   - Powered by the robust, lightweight `postgres:16-alpine` image.
   - Forwards port `5432:5432` to the host system.
   - Automatically bootstraps users, databases, and schemas on startup via a custom SQL initialization script (`init.sql`).
   - Persists data through a Docker named volume (`pgdata`).

2. **`toolbox` (MCP Database Toolbox Server)**:
   - Uses the official `us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest` image.
   - Operates in `network_mode: "host"`, granting it direct, low-latency access to the host's networking stack. This allows it to effortlessly communicate with the database container via `127.0.0.1:5432`.
   - Mounts and monitors the `./tools.yaml` configuration file.
   - Deploys the MCP server on port `5000`.

---

## 🔑 Setup, Credentials, & Database Access

### 📡 Network Connection Details
- **Database Host**: `127.0.0.1` (or `localhost`)
- **Database Port**: `5432`

### 👤 Database Roles & Credentials
- **Default Superuser**: `postgres` (with password `123456`)
- **Application User**: `toolbox_client` (with password `my-password`)
- **Application Database**: `toolbox_db`

---

## 📜 Database Schema & Seed Data

The database cluster is initialized using `init.sql`. The script configures the roles, creates the application database, grants necessary privileges, and sets up a `hotels` table tailored to the database tools.

### Database Table: `hotels`
| Column Name | Data Type | Modifiers | Description |
| :--- | :--- | :--- | :--- |
| **`id`** | `VARCHAR(255)` | `PRIMARY KEY` | Unique identifier for each hotel. |
| **`name`** | `VARCHAR(255)` | `NOT NULL` | Name of the hotel. |
| **`location`** | `VARCHAR(255)` | `NOT NULL` | City/Location of the hotel. |
| **`booked`** | `BIT(1)` | `DEFAULT B'0'` | Booking status bit (`B'0'` for available, `B'1'` for booked). |
| **`checkin_date`** | `DATE` | `NULLABLE` | Check-in date. |
| **`checkout_date`** | `DATE` | `NULLABLE` | Check-out date. |

### Seed Records
Four pre-populated hotels are automatically inserted upon first initialization:
1. `Grand Plaza Hotel` located in `New York`
2. `Seaside Resort` located in `Miami`
3. `Mountain Lodge` located in `Denver`
4. `Central Park Suites` located in `New York`

---

## 🛠️ MCP Toolset Definitions (`tools.yaml`)

The toolbox service exposes 5 main PostgreSQL-backed MCP tools linked to the `my-pg-source` source. These tools can be leveraged by any MCP-compliant client or agent:

1. **`search-hotels-by-name`**
   - **Description**: Search for hotels based on name.
   - **Parameters**: `name` (string)
   - **Statement**: `SELECT * FROM hotels WHERE name ILIKE '%' || $1 || '%';`

2. **`search-hotels-by-location`**
   - **Description**: Search for hotels based on location.
   - **Parameters**: `location` (string)
   - **Statement**: `SELECT * FROM hotels WHERE location ILIKE '%' || $1 || '%';`

3. **`book-hotel`**
   - **Description**: Book a hotel by its ID. Returns `NULL` on success, or raises an error if it fails.
   - **Parameters**: `hotel_id` (string)
   - **Statement**: `UPDATE hotels SET booked = B'1' WHERE id = $1;`

4. **`update-hotel`**
   - **Description**: Update a hotel's check-in and check-out dates by its ID.
   - **Parameters**: `hotel_id` (string), `checkin_date` (string), `checkout_date` (string)
   - **Statement**: `UPDATE hotels SET checkin_date = CAST($2 as date), checkout_date = CAST($3 as date) WHERE id = $1;`

5. **`cancel-hotel`**
   - **Description**: Cancel a hotel booking by its ID.
   - **Parameters**: `hotel_id` (string)
   - **Statement**: `UPDATE hotels SET booked = B'0' WHERE id = $1;`

---

## 🚀 Step-by-Step Usage Instructions

### 1. Free Up Port 5432 (Prerequisites)
If you have a local PostgreSQL service running on your host system, it will conflict with Docker's port mapping. Stop and disable it with:
```bash
sudo systemctl stop postgresql
sudo systemctl disable postgresql
```

### 2. Start the Services From Scratch
To ensure a completely clean start and trigger the PostgreSQL initialization scripts (`init.sql`):
```bash
docker-compose down -v && docker-compose up -d
```
*Note: The `-v` flag removes the previous data volume, forcing PostgreSQL to perform a clean initialization from scratch.*

### 3. Verify Startup & Initialization Logs
Check the PostgreSQL container logs to verify that the initialization script ran successfully:
```bash
docker logs postgres
```
You should see:
```text
/usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/init.sql
CREATE ROLE
CREATE DATABASE
GRANT
ALTER DATABASE
You are now connected to database "toolbox_db" as user "toolbox_client".
CREATE TABLE
INSERT 0 4
```

### 4. Query Seeded Data Directly
Verify the connection and query the `hotels` table as the `toolbox_client` user inside the running container:
```bash
PGPASSWORD=my-password docker exec -it postgres psql -U toolbox_client -d toolbox_db -c "SELECT * FROM hotels;"
```

### 5. Test the MCP Service (MCP Inspector)
The Model Context Protocol (MCP) server runs on the host interface via port `5000`. You can easily test and interact with the service using the **MCP Inspector** using the Server-Sent Events (SSE) transport endpoint:

- **SSE Transport Endpoint URL**: `http://127.0.0.1:5000/mcp/sse`

To launch the MCP Inspector connected to the running service, execute:
```bash
npx @modelcontextprotocol/inspector http://127.0.0.1:5000/mcp/sse
```
This launches a browser-based user interface where you can explore the 5 exposed tools, submit parameters, and view raw SQL results returned from your PostgreSQL database in real-time!

---

## 🐳 Custom Self-Contained Docker Image

A `Dockerfile` is provided to compile a custom, self-contained MCP Database Toolbox image. This image pre-packages your `tools.yaml` configuration file directly inside the image, allowing you to deploy the service without having to mount external configuration volumes at runtime.

### Building the Image
To build your custom toolbox image:
```bash
docker build -t custom-mcp-toolbox .
```

### Running the Custom Container
To run your custom self-contained MCP toolbox container (with database connectivity to your host/local postgres on port 5432):
```bash
docker run -d --name mcp-toolbox --network="host" custom-mcp-toolbox
```
This launches your pre-configured MCP Database Toolbox server directly on port `5000`!

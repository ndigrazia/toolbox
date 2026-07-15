-- Initialization script for the toolbox PostgreSQL database
CREATE USER toolbox_client WITH PASSWORD 'my-password';

CREATE DATABASE toolbox_db;
GRANT ALL PRIVILEGES ON DATABASE toolbox_db TO toolbox_client;

ALTER DATABASE toolbox_db OWNER TO toolbox_client;

-- Connect to toolbox_db as toolbox_client
\c toolbox_db toolbox_client

-- Create hotels table
CREATE TABLE IF NOT EXISTS hotels (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    booked BIT(1) DEFAULT B'0',
    checkin_date DATE,
    checkout_date DATE
);

-- Seed initial hotels data
INSERT INTO hotels (id, name, location, booked, checkin_date, checkout_date) VALUES
('1', 'Grand Plaza Hotel', 'New York', B'0', NULL, NULL),
('2', 'Seaside Resort', 'Miami', B'0', NULL, NULL),
('3', 'Mountain Lodge', 'Denver', B'0', NULL, NULL),
('4', 'Central Park Suites', 'New York', B'0', NULL, NULL)
ON CONFLICT (id) DO NOTHING;

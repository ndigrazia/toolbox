# Use the official Google Database Toolbox image as the base
FROM us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest

# Set the working directory
WORKDIR /app

# Build-time argument allowing users to specify an external tools configuration file
ARG TOOLS_FILE=tools.yaml

# Copy the tools configuration into the container
COPY ${TOOLS_FILE} /app/tools.yaml

# Run as non-root user
USER nobody

# Start the toolbox server using the static binary
ENTRYPOINT ["/toolbox"]
CMD ["--config", "/app/tools.yaml", "--address", "0.0.0.0", "--port", "5000"]

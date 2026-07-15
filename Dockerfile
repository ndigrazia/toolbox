# Use the official Google Database Toolbox image as the base
FROM us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest

# Set the working directory
WORKDIR /app

# Build-time argument allowing users to specify an external tools configuration file
ARG TOOLS_FILE=tools.yaml

# Copy the tools configuration into the container
COPY ${TOOLS_FILE} /app/tools.yaml

# Define default environment variables for configuration path and port
ENV CONFIG_PATH=/app/tools.yaml
ENV PORT=5000

# Expose the port variable
EXPOSE $PORT

# Run as non-root user
USER nobody

# Start the toolbox server with the pre-packaged configuration path and PORT env variables
ENTRYPOINT ["/bin/sh", "-c", "exec /toolbox --config $CONFIG_PATH --address 0.0.0.0 --port $PORT"]

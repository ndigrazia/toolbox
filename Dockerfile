# Use the official Google Database Toolbox image as the base
FROM us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest

# Set the working directory
WORKDIR /app

# Copy the tools.yaml configuration into the container
COPY tools.yaml /app/tools.yaml

# Define the default port environment variable
ENV PORT=5000

# Expose the port variable
EXPOSE $PORT

# Start the toolbox server with the pre-packaged configuration using the PORT env variable
ENTRYPOINT ["/bin/sh", "-c", "exec /toolbox --config /app/tools.yaml --address 0.0.0.0 --port $PORT"]

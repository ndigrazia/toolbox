# Use the official Google Database Toolbox image as the base
FROM us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest

# Set the working directory
WORKDIR /app

# Copy the tools.yaml configuration into the container
COPY tools.yaml /app/tools.yaml

# Expose port 5000 for the MCP server
EXPOSE 5000

# Pass default arguments to run the toolbox server with the pre-packaged configuration
CMD ["--config", "/app/tools.yaml", "--address", "0.0.0.0", "--port", "5000"]

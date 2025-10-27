# Use a modern Ubuntu  version
FROM ubuntu:latest

# Set non-interactive fronn
ENV DEBIAN_FRONTEND=noninteractive

#  Update package lists
RUN apt-get update && \
    apt-get install -y fortune-mod cowsay netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Copy the application script into the image
COPY wisecow.sh /usr/local/bin/wisecow.sh

# Making the script executable
RUN chmod +x /usr/local/bin/wisecow.sh

ENV PATH="/usr/games:${PATH}"
# Expose the port the server
EXPOSE 4499

# Define the command to run when the container starts
CMD ["/usr/local/bin/wisecow.sh"]

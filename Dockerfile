FROM alpine/git

# Copies the clone script to the Docker image
COPY mirror.sh /usr/local/bin/

# Makes the clone script executable
RUN chmod +x /usr/local/bin/mirror.sh

ENTRYPOINT [ "/usr/local/bin/mirror.sh" ]

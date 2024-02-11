ARG BASH_VERSION 

FROM "bash:$BASH_VERSION-alpine3.18"
ARG USER=testuser

# Install utilties for user management
RUN apk add shadow

# Add a non-root user with name "$USER"
# and set its default shell to bash
RUN useradd -m -s /bin/bash "$USER"

# Change the user's password to 'password'
RUN "$USER:password" | chpasswd

# Use the user $USER as the default user
# for the container image
USER "$USER" 


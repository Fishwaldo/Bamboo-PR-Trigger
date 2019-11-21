FROM debian:9.8-slim

LABEL "version"="1.0.0"
LABEL "repository"="https://github.com/Fishwaldo/Bamboo-PR-Trigger"
LABEL "homepage"="https://github.com/Fishwaldo/Bamboo-PR-Trigger"
LABEL "maintainer"="Justin Hammond <justin@dynam.ac>"
LABEL "com.github.actions.name"="Bamboo Trigger PR Build"
LABEL "com.github.actions.description"="Trigger a Bamboo Build for a Pull Request"
LABEL "com.github.actions.icon"="message-square"
LABEL "com.github.actions.color"="gray-dark"

# Install curl
RUN apt-get update && apt-get install -y curl ruby-full git bundler
ADD Bamboo-PR-Trigger /Bamboo-PR-Trigger/
RUN cd /Bamboo-PR-Trigger && bundler install 


# Add the entry point
ADD entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Load the entry point
ENTRYPOINT ["/entrypoint.sh"]

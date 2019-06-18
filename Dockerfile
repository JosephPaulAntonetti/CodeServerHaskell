FROM codercom/code-server

USER root

# Packages
RUN apt-get update && apt-get install --no-install-recommends -y \
    gpg \
    lsb-release \
    add-apt-key \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Common SDK
RUN apt-get update && apt-get install --no-install-recommends -y \
    gdb \
    pkg-config \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Code-Server
RUN apt-get update
RUN apt-get install --no-install-recommends -y \
     bsdtar \
     apt-transport-https \
     netbase \
     tar \
     software-properties-common \
     libffi-dev \
     libgmp-dev \
     zlib1g-dev \
     libicu-dev \
     libtinfo-dev \
     libgmp-dev

RUN add-apt-repository universe
RUN apt-add-repository -y "ppa:hvr/ghc"
RUN apt-get update
RUN apt-get install -y ghc-8.6.5
RUN rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
ENV DISABLE_TELEMETRY true

COPY install-extension.sh /home/coder/install-extension.sh
RUN chmod +x /home/coder/install-extension.sh
USER coder

ENV PATH=$PATH:$HOME/.local/bin:/opt/ghc/8.6.5/bin
# Setup Haskell Platform
RUN curl -sSL https://get.haskellstack.org/ | sh

#Setup HLint
RUN stack config set system-ghc --global true
RUN stack install hlint
RUN export PATH=$PATH:/home/coder/.local/bin

# Setup HIE
RUN cd ..
RUN cd ~ && git clone https://github.com/haskell/haskell-ide-engine --recurse-submodules
RUN cd ~/haskell-ide-engine && stack ./install.hs hie-8.6.5
RUN cd ~/haskell-ide-engine && ./install.hs build-doc
ENV PATH=$PATH:~/.local/bin

# Setup User Visual Studio Code Extentions
ENV VSCODE_USER "/home/coder/.local/share/code-server/User"
ENV VSCODE_EXTENSIONS "/home/coder/.local/share/code-server/extensions"

RUN mkdir -p ${VSCODE_USER}
WORKDIR /home/coder

# Install Extensions
RUN ./install-extension.sh justusadam language-haskell
RUN ./install-extension.sh alanz vscode-hie-server

RUN mkdir -p /home/coder/.local/share/code-server/User
COPY settings.json /home/coder/.local/share/code-server/User/settings.json

# Setup User Workspace
RUN mkdir -p /home/coder/project
WORKDIR /home/coder/project

ENTRYPOINT ["dumb-init", "code-server", "--allow-http", "--no-auth"]
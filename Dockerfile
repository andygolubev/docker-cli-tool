FROM ubuntu:23.10 AS install-stage
WORKDIR /tmp
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt -y upgrade && apt -y install wget unzip curl tree git jq gettext

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") \
        wget https://releases.hashicorp.com/terraform/1.7.3/terraform_1.7.3_linux_amd64.zip -O terraform.zip ;; \
      "linux/arm64") \
        wget https://releases.hashicorp.com/terraform/1.7.3/terraform_1.7.3_linux_arm64.zip -O terraform.zip ;; \
    esac && \
    unzip terraform.zip -d /usr/local/bin/ && \
    rm terraform.zip

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") \
        wget https://github.com/opentofu/opentofu/releases/download/v1.6.1/tofu_1.6.1_linux_amd64.zip -O tofu.zip ;; \
      "linux/arm64") \
        wget https://github.com/opentofu/opentofu/releases/download/v1.6.1/tofu_1.6.1_linux_arm64.zip -O tofu.zip ;; \
    esac && \
    unzip tofu.zip -d /usr/local/bin/ && \
    rm tofu.zip

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") \
        ARCH="amd64" ;; \
      "linux/arm64") \
        ARCH="arm64" ;; \
      *) \
        echo "Unsupported architecture for $TARGETPLATFORM"; exit 1 ;; \
    esac && \
    KUBECTL_URL="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    curl -LO "${KUBECTL_URL}" && \
    curl -LO "${KUBECTL_URL}.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl kubectl.sha256

RUN case "$TARGETPLATFORM" in \
      "linux/amd64") \
        ARCH="amd64" ;; \
      "linux/arm64") \
        ARCH="arm64" ;; \
      *) \
        echo "Unsupported architecture for $TARGETPLATFORM"; exit 1 ;; \
    esac && \
    DOCTL_URL="https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-${ARCH}.tar.gz" && \
    wget "${DOCTL_URL}" -O doctl.tar.gz && \
    tar -xf doctl.tar.gz -C /usr/local/bin && \
    rm doctl.tar.gz

RUN wget https://github.com/liquibase/liquibase/releases/download/v4.25.1/liquibase-4.25.1.tar.gz -O liquibase.tar.gz
RUN tar -xf liquibase.tar.gz -C /usr/local/bin

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

RUN chown root:root -R /usr/local/bin

# RUN echo "--- terraform ---"; terraform version; echo "--- doctl ---"; doctl version; echo "--- kubectl ---"; kubectl version; echo "--- helm ---"; helm version

FROM ubuntu:23.10
ENV DEBIAN_FRONTEND=noninteractive
COPY --from=install-stage /usr/local/bin /usr/local/bin
RUN apt update && apt -y upgrade && apt -y install sudo zsh wget unzip curl tree git jq gettext ca-certificates \ 
		nano vim default-jre ansible --no-install-suggests --no-install-recommends && ansible-galaxy collection install community.kubernetes

RUN useradd -m andy && adduser andy sudo
RUN mkdir -p /etc/sudoers.d/ && echo 'andy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/andy

USER andy
ENV SHELL=/bin/zsh
ENV HOME=/home/andy
WORKDIR $HOME

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

RUN git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/marlonrichert/zsh-autocomplete $HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting $HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting

RUN echo "export PATH=\$HOME/bin:/usr/local/bin:\$PATH" >> $HOME/.zshrc && \
    echo "export ZSH=\"\$HOME/.oh-my-zsh\"" >> $HOME/.zshrc && \
    echo "ZSH_THEME=\"robbyrussell\"" >> $HOME/.zshrc && \
    echo "zstyle ':omz:update' mode disabled" >> $HOME/.zshrc && \
    echo "plugins=(git zsh-autosuggestions zsh-autocomplete zsh-syntax-highlighting fast-syntax-highlighting)" >> $HOME/.zshrc && \
    echo "source \$ZSH/oh-my-zsh.sh" >> $HOME/.zshrc && \
    echo "[[ \$commands[kubectl] ]] && source <(kubectl completion zsh)" >> $HOME/.zshrc && \
    echo "alias k=\"kubectl\"" >> $HOME/.zshrc

CMD ["/bin/zsh"]
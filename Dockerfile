FROM ubuntu:23.10 AS install-stage
ARG TARGETPLATFORM
WORKDIR /tmp
ENV DEBIAN_FRONTEND=noninteractive

# create ARCH variable from TARGETPLATFORM: linux/arm64 -> arm64
RUN echo "ARCH=$(echo $TARGETPLATFORM | cut -d '/' -f2)" > /env.sh

RUN apt update && apt -y upgrade && apt -y install wget unzip curl tree git jq gettext

# . (dot) is a "source" analog
RUN . /env.sh && wget https://releases.hashicorp.com/terraform/1.7.3/terraform_1.7.3_linux_${ARCH}.zip -O terraform.zip
RUN unzip terraform.zip -d /usr/local/bin/

RUN . /env.sh && wget https://github.com/opentofu/opentofu/releases/download/v1.6.1/tofu_1.6.1_linux_${ARCH}.zip -O tofu.zip
RUN unzip tofu.zip -d /usr/local/bin/

RUN . /env.sh && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
RUN . /env.sh && curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl.sha256"
RUN echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN . /env.sh && wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-${ARCH}.tar.gz -O doctl.tar.gz
RUN tar -xf doctl.tar.gz -C /usr/local/bin

RUN wget https://github.com/liquibase/liquibase/releases/download/v4.25.1/liquibase-4.25.1.tar.gz -O liquibase.tar.gz
RUN tar -xf liquibase.tar.gz -C /usr/local/bin

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

RUN chown root:root -R /usr/local/bin

FROM ubuntu:23.10
ARG TARGETPLATFORM
ENV DEBIAN_FRONTEND=noninteractive
COPY --from=install-stage /usr/local/bin /usr/local/bin
# RUN apt update && apt -y upgrade && apt -y install sudo zsh wget unzip curl tree git jq gettext ca-certificates \ 
# 		nano vim default-jre ansible --no-install-suggests --no-install-recommends && ansible-galaxy collection install community.kubernetes

RUN apt update && apt -y install file

# RUN useradd -m andy && adduser andy sudo
# RUN mkdir -p /etc/sudoers.d/ && echo 'andy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/andy

# USER andy
# ENV SHELL=/bin/zsh
# ENV HOME=/home/andy
# WORKDIR $HOME

# RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# RUN git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
#     git clone https://github.com/marlonrichert/zsh-autocomplete $HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete && \
#     git clone https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
#     git clone https://github.com/zdharma-continuum/fast-syntax-highlighting $HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting

# RUN echo "export PATH=\$HOME/bin:/usr/local/bin:\$PATH" >> $HOME/.zshrc && \
#     echo "export ZSH=\"\$HOME/.oh-my-zsh\"" >> $HOME/.zshrc && \
#     echo "ZSH_THEME=\"robbyrussell\"" >> $HOME/.zshrc && \
#     echo "zstyle ':omz:update' mode disabled" >> $HOME/.zshrc && \
#     echo "plugins=(git zsh-autosuggestions zsh-autocomplete zsh-syntax-highlighting fast-syntax-highlighting)" >> $HOME/.zshrc && \
#     echo "source \$ZSH/oh-my-zsh.sh" >> $HOME/.zshrc && \
#     echo "[[ \$commands[kubectl] ]] && source <(kubectl completion zsh)" >> $HOME/.zshrc && \
#     echo "alias k=\"kubectl\"" >> $HOME/.zshrc

RUN echo "ARCH=$(echo $TARGETPLATFORM | cut -d '/' -f2)" > /env.sh

RUN . /env.sh && echo "target platform: $TARGETPLATFORM" > /etc/arch && \
    echo "arch: $ARCH" >> /etc/arch

CMD ["/bin/bash"]
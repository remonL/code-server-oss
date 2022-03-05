FROM cirrusci/flutter:dev

USER root

ENV USER="vs"

# install all dependencies
ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ=Asia/Shanghai
RUN apt-get update \
  && apt-get install --yes openjdk-8-jdk curl unzip sed git bash xz-utils  ssh  sudo wget sudo build-essential golang nodejs python3 zsh \
  && rm -rf /var/lib/{apt,dpkg,cache,log}

WORKDIR /home/

ENV RELEASE_TAG="1.65.0"
ENV RELEASE_ORG="remonL"
ENV VSCODE_ROOT="/home/${USER}/vscode-v${RELEASE_TAG}"

# Downloading the latest VSC Server release and extracting the release archive
RUN if [ -z "${RELEASE_TAG}" ]; then \
        echo "The RELEASE_TAG build arg must be set." >&2 && \
        exit 1; \
    fi && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="x64"; \
    elif [ "${arch}" = "aarch64" ]; then \
        arch="arm64"; \
    elif [ "${arch}" = "armv7l" ]; then \
        arch="armhf"; \
    fi && \
    mkdir -p ${VSCODE_ROOT} && \
    wget https://github.com/${RELEASE_ORG}/vscode/releases/download/vscode-v${RELEASE_TAG}/vscode-v${RELEASE_TAG}-linux-${arch}.tar.gz && \
    tar -xzf vscode-v${RELEASE_TAG}-linux-${arch}.tar.gz && \
    mv -f vscode-v${RELEASE_TAG}-linux-${arch} ${VSCODE_ROOT} && \
    rm -f vscode-v${RELEASE_TAG}-linux-${arch}.tar.gz

ARG USER="vs"
ARG USER_UID=1001
ARG USER_GID=$USER_UID

# Creating the user and usergroup
RUN groupadd --gid $USER_GID $USER \
    && useradd --uid $USER_UID --gid $USER -m $USER \
    && echo $USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

RUN chmod g+rw /home && \
    mkdir -p /home/workspace && \
    mkdir -p /home/$USER/.vscode-remote && \
    mkdir -p /home/$USER/.vscode-server-oss && \
    chown -R $USER:$USER /home/workspace && \
    chown -R $USER:$USER ${VSCODE_ROOT} && \
    chown -R $USER:$USER  /sdks && \
    chown -R $USER:$USER /home/$USER

WORKDIR /home/$USER/

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/$USER \
    EDITOR=code \
    VISUAL=code \
    GIT_EDITOR="code --wait" \
    VSCODE_ROOT=${VSCODE_ROOT}

RUN echo "ms-python.python esbenp.prettier-vscode visualstudioexptteam.vscodeintellicode eamodio.gitlens formulahendry.code-runner octref.vetur golang.go zhuangtongfa.material-theme editorconfig.editorconfig shd101wyy.markdown-preview-enhanced dbaeumer.vscode-eslint wix.vscode-import-cost leetcode.vscode-leetcode humao.rest-client vscjava.vscode-java-pack dart-code.flutter streetsidesoftware.code-spell-checker ms-vscode.cpptools webfreak.debug github.copilot github.codespaces wmaurer.change-case tabnine.tabnine-vscode msjsdiag.vscode-react-native wayou.vscode-todo-highlight" | xargs -n1 sh ${VSCODE_ROOT}/bin/code-server-oss --install-extension && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

USER root

ENV PORT=3000
ARG connectionToken="kkk"

EXPOSE $PORT

ENTRYPOINT [  ]

CMD [ "/bin/sh", "-c", "exec ${VSCODE_ROOT}/bin/code-server-oss --host=0.0.0.0 --port=${PORT} --connectionToken=${connectionToken} \"${@}\"", "--" ]

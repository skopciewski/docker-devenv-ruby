ARG BUILD_RUBY_VERSION
FROM ruby:${BUILD_RUBY_VERSION}-alpine

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories

RUN apk add --no-cache \
  ack \
  bash \
  build-base \
  ca-certificates \
  coreutils \
  ctags \
  curl \
  git \
  grep \
  htop \
  hub@testing\
  jq \
  less \
  libffi-dev \
  libnotify \
  make \
  mc \
  ncdu \
  ncurses \
  openssh-client \
  sudo \
  tmux@edge \
  tree \
  tzdata \
  util-linux \
  vim \
  zsh \
  zsh-vcs

ARG user=dev
ARG uid=1000
ARG gid=1000
ENV LANG=C.UTF-8
RUN echo 'export LANG="C.UTF-8"' > /etc/profile.d/lang.sh \
  && mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh || true \
  && mv /etc/profile.d/color_prompt.sh.disabled /etc/profile.d/color_prompt.sh || true \
  && addgroup -g ${gid} ${user} \
  && adduser -h /home/${user} -D -u ${uid} -G ${user} -s /bin/zsh ${user} \
  && echo "${user} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${user}" \
  && chmod 0440 "/etc/sudoers.d/${user}"

USER ${user}

ENV DEVDOTFILES_BASE_VER=1.1.1
RUN mkdir -p /home/${user}/opt \
  && cd /home/${user}/opt \
  && curl -fsSL https://github.com/skopciewski/dotfiles_base/archive/v${DEVDOTFILES_BASE_VER}.tar.gz | tar xz \
  && cd dotfiles_base-${DEVDOTFILES_BASE_VER} \
  && make

ENV DEVDOTFILES_VIM_VER=1.1.9
RUN mkdir -p /home/${user}/opt \
  && cd /home/${user}/opt \
  && curl -fsSL https://github.com/skopciewski/dotfiles_vim/archive/v${DEVDOTFILES_VIM_VER}.tar.gz | tar xz \
  && cd dotfiles_vim-${DEVDOTFILES_VIM_VER} \
  && make

ENV DEVDIR=/mnt/devdir
WORKDIR ${DEVDIR}

# configure bundler to keep things outside the app
ENV BUNDLE_APP_GEMS  /home/${user}/opt/gems
RUN mkdir "${BUNDLE_APP_GEMS}" \
  && bundle config console pry \
  && bundle config build.nokogiri --use-system-libraries \
  && bundle config path "${BUNDLE_APP_GEMS}" \
  && bundle config bin "${BUNDLE_APP_GEMS}/bin"

# copy gemrc and gem utils
COPY data/gemrc /home/${user}/.gemrc
RUN GEM_HOME=$(ruby -e "print Gem.user_dir") gem install pry json

# Prepare dotfiles
ARG BUILD_RUBY_VERSION
ENV DEVDOTFILES_VIM_RUBY_VER=1.0.10
RUN mkdir -p /home/${user}/opt \
  && cd /home/${user}/opt \
  && curl -fsSL https://github.com/skopciewski/dotfiles_vim_ruby/archive/v${DEVDOTFILES_VIM_RUBY_VER}.tar.gz | tar xz \
  && cd dotfiles_vim_ruby-${DEVDOTFILES_VIM_RUBY_VER} \
  && PATH=/home/${user}/sbin:$PATH make \
  && sed -i -e "s/TargetRubyVersion: .*/TargetRubyVersion: ${BUILD_RUBY_VERSION}/" /home/${user}/.rubocop.yml

ENV ZSH_TMUX_AUTOSTART=true \
  ZSH_TMUX_AUTOSTART_ONCE=true \
  ZSH_TMUX_AUTOCONNECT=false \
  ZSH_TMUX_AUTOQUIT=false \
  ZSH_TMUX_FIXTERM=false \
  TERM=xterm-256color

CMD ["/bin/zsh"]

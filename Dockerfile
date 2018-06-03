FROM skopciewski/devenv-base

USER root

RUN apk add --no-cache \
      ctags \
      libnotify \
      ruby \
      ruby-io-console \
      ruby-bundler \
      ruby-rake \
      ca-certificates \
      build-base \
      libffi-dev \
      ruby-dev

ARG user=dev
USER ${user}

# configure bundler
ENV BUNDLE_APP_CONFIG  /home/${user}/opt/bundle
RUN mkdir ${BUNDLE_APP_CONFIG} \
  && touch ${BUNDLE_APP_CONFIG}/config 

RUN bundle config console pry \
  && bundle config build.nokogiri --use-system-libraries

# copy gemrc and gem utils
COPY data/gemrc /home/${user}/.gemrc
RUN gem install pry json

# Prepare dotfiles
ENV DEVDOTFILES_VIM_RUNB_VER=1.0.1
RUN mkdir -p /home/${user}/opt \
  && cd /home/${user}/opt \
  && curl -fsSL https://github.com/skopciewski/dotfiles_vim_ruby/archive/v${DEVDOTFILES_VIM_RUNB_VER}.tar.gz | tar xz \
  && cd dotfiles_vim_ruby-${DEVDOTFILES_VIM_RUNB_VER} \
  && PATH=/home/${user}/sbin:$PATH make

ENV ZSH_TMUX_AUTOSTART=true \
  ZSH_TMUX_AUTOSTART_ONCE=true \
  ZSH_TMUX_AUTOCONNECT=false \
  ZSH_TMUX_AUTOQUIT=false \
  ZSH_TMUX_FIXTERM=false \
  TERM=xterm-256color

CMD ["/bin/zsh"]

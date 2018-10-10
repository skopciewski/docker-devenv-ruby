FROM skopciewski/devenv-base

USER root

RUN apk add --no-cache \
      build-base \
      ca-certificates \
      ctags \
      libffi-dev \
      libnotify \
      ruby \
      ruby-bigdecimal \
      ruby-bundler \
      ruby-dev \
      ruby-etc \
      ruby-io-console \
      ruby-irb \
      ruby-rake

ARG user=dev
USER ${user}

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
ENV DEVDOTFILES_VIM_RUNB_VER=1.0.5
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

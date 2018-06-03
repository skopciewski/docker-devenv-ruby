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

# install gems globally, for great justice
ENV GEM_HOME /home/${user}/opt/gems
ENV PATH $GEM_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# local bundler config outside project
ENV BUNDLE_APP_CONFIG  /home/${user}/opt/bundle
RUN mkdir ${BUNDLE_APP_CONFIG} \
  && touch ${BUNDLE_APP_CONFIG}/config 

# configure bundler to use global gems
RUN bundle config path "$GEM_HOME" \
  && bundle config bin "$GEM_HOME/bin" \
  && bundle config console pry

# copy gemrc and gem utils
COPY data/gemrc /home/${user}/.gemrc

RUN gem install pry json
RUN bundle config build.nokogiri --use-system-libraries

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

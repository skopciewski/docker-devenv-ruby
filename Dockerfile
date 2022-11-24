FROM skopciewski/devenv-base:latest
ARG BUILD_RUBY_VERSION

USER root

RUN \
  : "${BUILD_RUBY_VERSION:?Build argument BUILD_RUBY_VERSION needs to be set and non-empty.}" \
  && echo "${BUILD_RUBY_VERSION}" > /.ruby-version

RUN apk add --no-cache \
  build-base \
  ca-certificates \
  gdbm-dev \
  libffi-dev \
  libxml2-dev \
  libxslt-dev \
  npm \
  readline-dev \
  tidyhtml \
  yaml-dev \
  zlib-dev
RUN if [ "$BUILD_RUBY_VERSION" = "2.7" ] ; then apk add --no-cache openssl1.1-compat-dev ; else apk add --no-cache openssl-dev ; fi

ARG user=dev
USER ${user}

# install ruby
COPY --chown=${user}:${user} data/gemrc /home/${user}/.gemrc
COPY --chown=${user}:${user} data/chruby.zshrc /home/${user}/.zshrc_local_conf/
RUN mkdir -p /home/${user}/src \
  && cd /home/${user}/src \
  && wget -O ruby-install-0.8.3.tar.gz https://github.com/postmodern/ruby-install/archive/v0.8.3.tar.gz \
  && tar -xzf ruby-install-0.8.3.tar.gz \
  && cd ruby-install-0.8.3/ \
  && sudo make install \
  && cd .. \
  && wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz \
  && tar -xzvf chruby-0.3.9.tar.gz \
  && cd chruby-0.3.9/ \
  && sudo make install \
  && cd ../.. \
  && ruby-install -j "$(nproc)" ruby ${BUILD_RUBY_VERSION} -- --enable-shared --disable-install-doc \
  && rm -rf /home/${user}/src

# configure bundler to keep things outside the app, install utils
SHELL ["/bin/zsh", "-c"]
ENV BUNDLE_APP_GEMS /mnt/gems
RUN \
  sudo mkdir -p ${BUNDLE_APP_GEMS} \
  && sudo chown ${user}:${user} ${BUNDLE_APP_GEMS} \
  && source /usr/local/share/chruby/chruby.sh \
  && chruby ruby-${BUILD_RUBY_VERSION} \
  && bundle config console pry \
  && bundle config build.nokogiri --use-system-libraries \
  && bundle config path "${BUNDLE_APP_GEMS}" \
  && bundle config bin "${BUNDLE_APP_GEMS}/bin" \
  && gem install pry json standardrb
SHELL ["/bin/sh", "-c"]

# configure npm
ENV HOST_NODE_MODULES /home/${user}/.npm/modules
RUN mkdir -p "${HOST_NODE_MODULES}" \
  && npm config set prefix ${HOST_NODE_MODULES} \
  && echo "export PATH=${HOST_NODE_MODULES}/bin:\$PATH" > /home/${user}/.zshrc_local_conf/npm_env.zshrc \
  && npm install --global stylelint stylelint-config-standard standard

# configure vim
COPY --chown=${user}:${user} data/vim_plugins.txt /home/${user}/
COPY --chown=${user}:${user} data/plugin/ /home/${user}/.vim/plugin/
COPY --chown=${user}:${user} data/ftplugin/ /home/${user}/.vim/ftplugin/
COPY --chown=${user}:${user} data/coc-settings.json /home/${user}/.vim/
COPY --chown=${user}:${user} data/stylelintrc /mnt/.stylelintrc
COPY --chown=${user}:${user} data/tidyrc /mnt/.tidyrc
RUN rm -f /home/${user}/.vim/plugin/base/ale.vim
RUN mkdir -p /home/${user}/.vim/pack/ruby/start \
  && for plugin in $(cat /home/${user}/vim_plugins.txt); do \
    echo "*** Installing: $plugin ***"; \
    $(cd /home/${user}/.vim/pack/ruby/start/ && git clone --depth 1 $plugin 2>/dev/null); \
  done \
  && echo "*** Installing: coc ***" \
  && $(cd /home/${user}/.vim/pack/ruby/start/ && git clone --branch v0.0.82 https://github.com/neoclide/coc.nvim.git --depth=1 2>/dev/null) \
  && mkdir -p /home/${user}/.config/coc \
  && vim -c 'CocInstall -sync coc-solargraph coc-html coc-json coc-css|qall'

CMD ["/bin/zsh"]

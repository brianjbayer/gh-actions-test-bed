# --- Base Image ---
ARG BASE_IMAGE=ruby:3.4.8-slim-trixie
FROM ${BASE_IMAGE} AS ruby-base

#--- Base Builder Stage ---
FROM ruby-base AS base-builder

# Use the same version of Bundler in the Gemfile.lock
ARG BUNDLER_VERSION=4.0.3
ENV BUNDLER_VERSION=${BUNDLER_VERSION}

# Install base build packages
# ARG BASE_BUILD_PACKAGES='build-essential libyaml-dev'
ARG BASE_BUILD_PACKAGES='build-essential'

# Assumes debian based
RUN apt-get update \
  && apt-get -y dist-upgrade \
  && apt-get -y install ${BASE_BUILD_PACKAGES} \
  && rm -rf /var/lib/apt/lists/* \
  # Update gem command to latest
  && gem update --system \
  # Install bundler
  && gem install bundler:${BUNDLER_VERSION}

# Install the Ruby dependencies (defined in the Gemfile/Gemfile.lock)
WORKDIR /app
COPY Gemfile Gemfile.lock ./

#--- Dev Environment Builder Stage ---
FROM base-builder AS devenv-builder

# git is needed for bundler audit
ARG DEVENV_PACKAGES='git vim'

# NOTE: App specific
ARG BUNDLER_PATH=/usr/local/bundle

# Install dev environment specific build packages
# Assumes debian based
RUN apt-get update \
  && apt-get -y dist-upgrade \
  && apt-get -y install ${DEVENV_PACKAGES} \
  && rm -rf /var/lib/apt/lists/* \
  # Add support for multiple platforms
  && bundle lock --add-platform ruby \
  && bundle lock --add-platform x86_64-linux \
  && bundle lock --add-platform aarch64-linux \
  # Install app dependencies
  && bundle install \
  # Remove unneeded files (cached *.gem, *.o, *.c)
  && rm -rf ${BUNDLER_PATH}/cache/*.gem \
  && find ${BUNDLER_PATH}/gems/ -name '*.[co]' -delete

# --- Dev Environment Image ---
FROM devenv-builder AS devenv

WORKDIR /app

# Start devenv in (command line) shell
CMD ["bash"]

#--- Deploy Builder Stage ---
FROM base-builder AS deploy-builder

ARG BUNDLER_PATH=/usr/local/bundle

RUN bundle config set --local without 'development:test' \
    # Add support for multiple platforms
    && bundle lock --add-platform ruby \
    && bundle lock --add-platform x86_64-linux \
    && bundle lock --add-platform aarch64-linux \
    # Install app dependencies
    && bundle install \
    # Remove unneeded files (cached *.gem, *.o, *.c)
    && rm -rf ${BUNDLER_PATH}/cache/*.gem \
    && find ${BUNDLER_PATH}/gems/ -name '*.[co]' -delete \
    # Configure bundler to lock to Gemfile.lock
    && bundle config --global frozen 1

#--- Deploy Image ---
FROM ruby-base AS deploy

# Use the same version of Bundler in the Gemfile.lock
ARG BUNDLER_VERSION=2.7.2
ENV BUNDLER_VERSION=${BUNDLER_VERSION}

# Add user for running app
RUN useradd -m -s /bin/bash -c '' deployer && usermod -L deployer
USER deployer

WORKDIR /app

# Copy the built gems directory from builder layer
COPY --from=deploy-builder --chown=deployer /usr/local/bundle/ /usr/local/bundle/

# Copy the app source
COPY --chown=deployer . /app/

CMD ["echo", "It's Alive!"]

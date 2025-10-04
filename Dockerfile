# --- Base Image ---
ARG BASE_IMAGE=ruby:3.4.6-alpine
FROM ${BASE_IMAGE} AS ruby-base

#--- Base Builder Stage ---
FROM ruby-base AS base-builder

# Use the same version of Bundler in the Gemfile.lock
ARG BUNDLER_VERSION=2.7.2
ENV BUNDLER_VERSION=${BUNDLER_VERSION}

# Install base build packages needed for both devenv and deploy builders
# Alpine needs build-base for building native extensions
ARG BASE_BUILD_PACKAGES='build-dependencies build-base'

RUN apk --update add --virtual ${BASE_BUILD_PACKAGES} \
  # Update gem command to latest
  && gem update --system \
  # Install bundler version
  && gem install bundler:${BUNDLER_VERSION}

# Copy Gemfiles
WORKDIR /app
COPY Gemfile Gemfile.lock ./

#--- Dev Environment Builder Stage ---
FROM base-builder AS devenv-builder

# git is needed for bundler audit
ARG DEVENV_PACKAGES='git vim'

# NOTE: App specific
ARG BUNDLER_PATH=/usr/local/bundle

# Install dev environment specific build packages
RUN apk add --no-cache ${DEVENV_PACKAGES} \
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
CMD ["sh"]

#--- Deploy Builder Stage ---
FROM base-builder AS deploy-builder

ARG BUNDLER_PATH=/usr/local/bundle

RUN bundle config set --local without 'development:test' \
    # Add support for multiple platforms
    && bundle lock --add-platform ruby \
    && bundle lock --add-platform x86_64-linux \
    && bundle lock --add-platform aarch64-linux \
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
RUN adduser -D deployer
USER deployer

WORKDIR /app

# Copy the built gems directory from builder layer
COPY --from=deploy-builder --chown=deployer /usr/local/bundle/ /usr/local/bundle/

# Copy the app source
COPY --chown=deployer . /app/

CMD ["echo", "It's Alive!"]

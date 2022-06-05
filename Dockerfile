FROM ruby:3-bullseye

ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT true
ENV BUNDLER_WITHOUT development test
WORKDIR /redmine

# Build stage 1
COPY docker/build1 /docker/build1
RUN /docker/build1/run.sh

# Build stage 2
COPY docker/build2 /docker/build2
COPY redmine/Gemfile* /redmine/
RUN /docker/build2/run.sh

# Copy all files
COPY redmine /redmine/
COPY docker /docker/
RUN ln -sf /docker/rmops /usr/local/bin

EXPOSE 8080 2222
ENTRYPOINT ["rmops", "entrypoint"]


FROM ruby:3.4-slim

WORKDIR /app

# Cài công cụ biên dịch native gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Sử dụng đúng Bundler version trong Gemfile.lock
RUN gem install bundler -v 2.7.2

COPY Gemfile Gemfile.lock ./

RUN bundle _2.7.2_ install

COPY . .

EXPOSE 9292

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:9292"]

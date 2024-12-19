source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

# backend
gem "rails", "~> 8.0.0"
gem "pg", "~> 1.1"
gem "redis", "~> 5.0"
gem "puma", "~> 6.0"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "dotenv-rails"
gem "activerecord-session_store"

# shopify
gem "shopify_app", "~> 22.5.0"
gem "polaris_view_components", "~> 2.0"
gem "shopify_graphql", "~> 2.0"

# frontend
gem "sprockets-rails"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "money"
gem "net-pop"
gem "iso_country_codes"
gem "money-open-exchange-rates", "~> 1.4"
group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "http_logger"
end

group :development do
  gem "web-console"
  gem "pry-rails"
  gem "hotwire-livereload"
  gem "foreman"
end

group :test do
  gem "mocha"
  gem "capybara"
  gem "selenium-webdriver"
  gem "vcr"
  gem "webmock"
end

source "https://rubygems.org"

gem "rails", "~> 8.0.0"
gem "sqlite3", ">= 1.4"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "pagy"
gem "rack-attack"
gem "sidekiq"
gem "redis"
gem "datadog", require: "datadog/auto_instrument"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
end

group :test do
  gem "simplecov", require: false
end

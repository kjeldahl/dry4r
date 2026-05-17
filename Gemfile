# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "crap4r", git: "https://github.com/kjeldahl/crap4r.git", require: false
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.13"
  gem "rubocop", "~> 1.65", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
  gem "simplecov", "~> 0.22", require: false
end

group :development do
  gem "mutant-rspec", require: false
end

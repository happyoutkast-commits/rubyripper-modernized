source "https://rubygems.org"

ruby ">= 3.3.0"

# Ruby standard-library components that are distributed as gems on modern Ruby.
gem "base64", require: false
gem "cgi", require: false
gem "rexml"

# Optional application features. Keep these out of headless CI while the
# existing GTK3 frontend and translation stack are validated separately.
group :gui do
  gem "gtk3", require: false
end

group :i18n do
  gem "gettext", require: false
end

group :development, :test do
  gem "aruba", "~> 2.4", require: false
  gem "cucumber", "~> 11.1"
  gem "rspec", "~> 3.13"
end

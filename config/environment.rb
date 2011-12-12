# Load the rails application
require File.expand_path('../application', __FILE__)

#OpenIdAuthentication.store = :file

OpenID.fetcher.ca_file = "#{Rails.root}/config/ca-bundle.crt"

# Initialize the rails application
OpenidTest::Application.initialize!

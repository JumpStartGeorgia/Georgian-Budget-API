require 'devise'

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers
  config.include Devise::TestHelpers, type: :view

  # Warden is used to stub authentication in feature specs: https://github.com/plataformatec/devise/wiki/How-To:-Test-with-Capybara
  config.include Warden::Test::Helpers
  Warden.test_mode!
end

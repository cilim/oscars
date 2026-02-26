module AuthenticationHelpers
  def sign_in(user)
    post session_path, params: {
      email_address: user.email_address,
      password: "password123"
    }
  end

  def sign_in_as_admin
    admin = create(:user, :admin)
    sign_in(admin)
    admin
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end

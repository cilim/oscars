require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /registration/new" do
    it "renders the registration form" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /registration" do
    it "creates a user and signs them in" do
      expect {
        post registration_path, params: {
          user: {
            display_name: "Test User",
            email_address: "test@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Test User")
    end

    it "re-renders form with errors for invalid data" do
      post registration_path, params: {
        user: { display_name: "", email_address: "", password: "short" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

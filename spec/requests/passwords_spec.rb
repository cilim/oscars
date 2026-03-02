require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user) }

  describe "GET /passwords/new" do
    it "returns 200" do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    it "redirects to sign-in with notice when user exists" do
      post passwords_path, params: { email_address: user.email_address }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to be_present
    end

    it "still redirects with notice when user does not exist" do
      post passwords_path, params: { email_address: "nobody@example.com" }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to be_present
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the reset form with a valid token" do
      get edit_password_path(user.password_reset_token)
      expect(response).to have_http_status(:ok)
    end

    it "redirects to new_password with alert for an invalid token" do
      get edit_password_path("totally-invalid-token")
      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /passwords/:token" do
    it "resets the password and redirects to sign-in" do
      token = user.password_reset_token
      patch password_path(token), params: { password: "newpassword1", password_confirmation: "newpassword1" }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to be_present
    end

    it "redirects with alert when passwords do not match" do
      token = user.password_reset_token
      patch password_path(token), params: { password: "newpassword1", password_confirmation: "different" }
      expect(response).to redirect_to(edit_password_path(token))
      expect(flash[:alert]).to be_present
    end
  end
end

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /session/new" do
    it "returns 200 when unauthenticated" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    it "signs in with valid credentials and redirects to root" do
      post session_path, params: { email_address: user.email_address, password: "password123" }
      expect(response).to redirect_to(root_url)
    end

    it "redirects to new_session with alert on wrong password" do
      post session_path, params: { email_address: user.email_address, password: "wrong" }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to be_present
    end

    it "redirects to stored return_to URL after sign-in" do
      # Trigger request_authentication to store a return URL
      get edit_season_picks_path(create(:season))
      expect(session[:return_to_after_authenticating]).to be_present

      post session_path, params: { email_address: user.email_address, password: "password123" }
      expect(response).to have_http_status(:redirect)
      # after_authentication_url clears the stored key and returns it
      expect(session[:return_to_after_authenticating]).to be_nil
    end
  end

  describe "DELETE /session" do
    it "signs out and redirects to new_session" do
      sign_in(user)
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end

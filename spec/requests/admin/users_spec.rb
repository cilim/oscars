require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  before { sign_in(admin) }

  describe "GET /admin/users" do
    it "returns 200" do
      get admin_users_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/users/new" do
    it "returns 200" do
      get new_admin_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/users" do
    it "creates a user and redirects" do
      expect {
        post admin_users_path, params: {
          user: { email_address: "new@example.com", display_name: "New User",
                  password: "password123", password_confirmation: "password123", admin: false }
        }
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(admin_users_path)
    end

    it "re-renders new on invalid params" do
      post admin_users_path, params: {
        user: { email_address: "", display_name: "", password: "x", password_confirmation: "y" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/users/:id/edit" do
    it "returns 200" do
      user = create(:user)
      get edit_admin_user_path(user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/users/:id" do
    let(:user) { create(:user) }

    it "updates display_name and redirects" do
      patch admin_user_path(user), params: {
        user: { email_address: user.email_address, display_name: "Updated",
                password: "", password_confirmation: "" }
      }
      expect(user.reload.display_name).to eq("Updated")
      expect(response).to redirect_to(admin_users_path)
    end

    it "re-renders edit on invalid params" do
      patch admin_user_path(user), params: {
        user: { email_address: "", display_name: "", password: "", password_confirmation: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "ignores blank password fields (does not clear password)" do
      original_digest = user.password_digest
      patch admin_user_path(user), params: {
        user: { email_address: user.email_address, display_name: "Same",
                password: "", password_confirmation: "" }
      }
      expect(user.reload.password_digest).to eq(original_digest)
    end
  end

  describe "DELETE /admin/users/:id" do
    it "destroys another user and redirects" do
      other = create(:user)
      expect { delete admin_user_path(other) }.to change(User, :count).by(-1)
      expect(response).to redirect_to(admin_users_path)
    end

    it "prevents deleting yourself" do
      expect { delete admin_user_path(admin) }.not_to change(User, :count)
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include("cannot delete yourself")
    end
  end

  describe "as regular user" do
    let(:user) { create(:user) }
    before { sign_in(user) }

    it "redirects to root" do
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end
end

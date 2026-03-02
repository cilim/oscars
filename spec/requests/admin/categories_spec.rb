require "rails_helper"

RSpec.describe "Admin::Categories", type: :request do
  let(:admin) { create(:user, :admin) }
  before { sign_in(admin) }

  describe "GET /admin/categories" do
    it "returns 200" do
      get admin_categories_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/categories/new" do
    it "returns 200" do
      get new_admin_category_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/categories" do
    it "creates a category and redirects" do
      expect {
        post admin_categories_path, params: { category: { name: "Best VFX", has_person: false } }
      }.to change(Category, :count).by(1)
      expect(response).to redirect_to(admin_categories_path)
    end

    it "re-renders new on invalid params" do
      post admin_categories_path, params: { category: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/categories/:id/edit" do
    it "returns 200" do
      cat = create(:category)
      get edit_admin_category_path(cat)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/categories/:id" do
    let(:cat) { create(:category) }

    it "updates the category and redirects" do
      patch admin_category_path(cat), params: { category: { name: "Updated Name" } }
      expect(cat.reload.name).to eq("Updated Name")
      expect(response).to redirect_to(admin_categories_path)
    end

    it "re-renders edit on invalid params" do
      patch admin_category_path(cat), params: { category: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/categories/:id" do
    it "destroys the category and redirects" do
      cat = create(:category)
      expect { delete admin_category_path(cat) }.to change(Category, :count).by(-1)
      expect(response).to redirect_to(admin_categories_path)
    end
  end

  describe "as regular user" do
    let(:user) { create(:user) }
    before { sign_in(user) }

    it "redirects to root" do
      get admin_categories_path
      expect(response).to redirect_to(root_path)
    end
  end
end

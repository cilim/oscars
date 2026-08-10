RSpec.describe PickType, type: :model do
  describe "max selections for single-select" do
    it "clears max_selections before validation" do
      pick_type = build(:pick_type, allow_multiple_selections: false, max_selections: 3)

      expect(pick_type).to be_valid
      expect(pick_type.max_selections).to be_nil
    end
  end
end

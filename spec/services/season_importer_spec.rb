require "rails_helper"

RSpec.describe SeasonImporter do
  let(:data) do
    {
      "season"     => { "name" => "97th Academy Awards (2025)", "year" => 2025 },
      "categories" => [
        {
          "name"       => "Best Picture",
          "has_person" => false,
          "nominees"   => [
            { "movie" => "Anora",        "person" => nil,  "poster_url" => "https://img.example.com/anora.jpg" },
            { "movie" => "The Brutalist", "person" => nil,  "poster_url" => nil }
          ]
        },
        {
          "name"       => "Best Actor",
          "has_person" => true,
          "nominees"   => [
            { "movie" => "The Brutalist", "person" => "Adrien Brody",      "poster_url" => nil },
            { "movie" => "A Complete Unknown", "person" => "Timothée Chalamet", "poster_url" => nil }
          ]
        }
      ]
    }
  end

  subject(:importer) { described_class.new(data) }

  describe "#call" do
    it "returns the created Season" do
      expect(importer.call).to be_a(Season)
    end

    it "creates a Season record" do
      expect { importer.call }.to change(Season, :count).by(1)
    end

    it "sets the season name" do
      expect(importer.call.name).to eq("97th Academy Awards (2025)")
    end

    it "sets the season year" do
      expect(importer.call.year).to eq(2025)
    end

    it "creates Category records for each category" do
      expect { importer.call }.to change(Category, :count).by(2)
    end

    it "creates SeasonCategory join records" do
      expect { importer.call }.to change(SeasonCategory, :count).by(2)
    end

    it "creates Nominee records" do
      expect { importer.call }.to change(Nominee, :count).by(4)
    end

    it "sets poster_url when provided" do
      importer.call
      expect(Nominee.find_by(movie_name: "Anora").poster_url).to eq("https://img.example.com/anora.jpg")
    end

    it "leaves poster_url nil when not provided" do
      importer.call
      expect(Nominee.find_by(movie_name: "The Brutalist", person_name: nil).poster_url).to be_nil
    end

    it "sets person_name for person categories" do
      importer.call
      expect(Nominee.find_by(person_name: "Adrien Brody")).to be_present
    end

    it "records no errors on success" do
      importer.call
      expect(importer.errors).to be_empty
    end

    context "idempotency — importing the same data twice" do
      before { importer.call }

      it "does not create a duplicate Season" do
        expect { described_class.new(data).call }.not_to change(Season, :count)
      end

      it "does not create duplicate Categories" do
        expect { described_class.new(data).call }.not_to change(Category, :count)
      end

      it "does not create duplicate Nominees" do
        expect { described_class.new(data).call }.not_to change(Nominee, :count)
      end

      it "updates the season name if it changed" do
        updated = data.deep_dup
        updated["season"]["name"] = "97th Academy Awards (Updated)"
        described_class.new(updated).call
        expect(Season.find_by(year: 2025).name).to eq("97th Academy Awards (Updated)")
      end
    end

    context "with blank category names" do
      let(:data) do
        {
          "season"     => { "name" => "Test Season", "year" => 2030 },
          "categories" => [
            { "name" => "",             "has_person" => false, "nominees" => [ { "movie" => "Film A" } ] },
            { "name" => "Best Picture", "has_person" => false, "nominees" => [ { "movie" => "Film A" } ] }
          ]
        }
      end

      it "skips the blank-named category" do
        expect { importer.call }.to change(Category, :count).by(1)
      end
    end

    context "with blank movie names in nominees" do
      let(:data) do
        {
          "season"     => { "name" => "Test Season", "year" => 2031 },
          "categories" => [
            {
              "name"       => "Best Picture",
              "has_person" => false,
              "nominees"   => [
                { "movie" => "",      "person" => nil, "poster_url" => nil },
                { "movie" => "Anora", "person" => nil, "poster_url" => nil }
              ]
            }
          ]
        }
      end

      it "skips the blank-named nominee" do
        expect { importer.call }.to change(Nominee, :count).by(1)
      end
    end

    context "with empty categories list" do
      let(:data) do
        { "season" => { "name" => "Empty Season", "year" => 2032 }, "categories" => [] }
      end

      it "still creates the season" do
        expect { importer.call }.to change(Season, :count).by(1)
      end

      it "creates no categories or nominees" do
        expect { importer.call }.not_to change(Category, :count)
      end
    end

    context "when a record fails validation" do
      before do
        allow_any_instance_of(Season).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new(Season.new)
        )
      end

      it "returns nil" do
        expect(importer.call).to be_nil
      end

      it "records an error message" do
        importer.call
        expect(importer.errors).not_to be_empty
      end

      it "rolls back the transaction (no Season created)" do
        expect { importer.call }.not_to change(Season, :count)
      end
    end
  end
end

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :display_name, null: false
      t.boolean :admin, default: false, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end

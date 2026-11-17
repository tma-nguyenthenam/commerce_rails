class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.string :slug
      t.string :image_url
      t.string :promo_banner
      t.string :background_card
      t.string :tagline
      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true
  end
end

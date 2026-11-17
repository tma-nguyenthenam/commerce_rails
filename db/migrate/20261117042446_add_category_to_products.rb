class AddCategoryToProducts < ActiveRecord::Migration[8.0]
  def change
    add_reference :products, :category, null: true, foreign_key: true

    add_column :products, :description, :text
    add_column :products, :colors,      :string, array: true, default: []
    add_column :products, :options,     :jsonb,  default: {}
    add_column :products, :thumbnail,   :string
    add_column :products, :images,      :string, array: true, default: []
    add_column :products, :slug,        :string
    add_column :products, :is_new,      :boolean
    add_column :products, :tagline,     :string

    add_index :products, :colors,  using: :gin
    add_index :products, :images,  using: :gin
    add_index :products, :options, using: :gin
    add_index :products, :slug,    unique: true
  end
end

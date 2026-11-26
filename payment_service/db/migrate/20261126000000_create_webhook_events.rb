class CreateWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_events do |t|
      t.string :event_id, null: false
      t.string :event_type, null: false

      t.jsonb :payload, null: false

      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0

      t.datetime :received_at, null: false
      t.datetime :processed_at

      t.text :last_error

      t.timestamps
    end

    add_index :webhook_events, :event_id, unique: true
    add_index :webhook_events, :status
  end
end

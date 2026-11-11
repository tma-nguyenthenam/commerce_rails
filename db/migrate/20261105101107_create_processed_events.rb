class CreateProcessedEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :processed_events do |t|
      t.string :external_event_id, null: false
      t.timestamps
    end
    # Webhook gửi trùng thì unique index chặn lần thứ hai
    add_index :processed_events, :external_event_id, unique: true
  end
end

class CreateCalls < ActiveRecord::Migration[5.1]
  def change
    create_table :calls do |t|
      t.string :status
      t.integer :duration
      t.string :phone_number, null: false
      t.string :phone_state
      t.string :phone_country
      t.integer :digit
      t.string :recording_url
      t.integer :recording_duration
      t.datetime :hangup_at
      t.timestamps
    end
  end
end

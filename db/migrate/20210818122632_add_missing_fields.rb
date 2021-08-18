class AddMissingFields < ActiveRecord::Migration[5.2]
  def change

    add_column :users, :temp_id, :string
    add_column :users, :instance_id, :string
    add_column :users, :encrypted_password, :string
    add_column :users, :aud, :string
    add_column :users, :email_confirmed_at, :timestamp
    add_column :users, :invited_at, :timestamp

    add_column :users, :phone, :string
    add_column :users, :phone_confirmed_at, :timestamp

    add_column :users, :confirmation_token, :string
    add_column :users, :confirmation_sent_at, :timestamp
    add_column :users, :confirmed_at, :timestamp

    add_column :users, :recovery_token, :string
    add_column :users, :recovery_sent_at, :timestamp

    add_column :users, :email_change_token, :string
    add_column :users, :email_change, :string
    add_column :users, :email_change_sent_at, :timestamp

    add_column :users, :phone_change_token, :string
    add_column :users, :phone_change, :string
    add_column :users, :phone_change_sent_at, :timestamp

    add_column :users, :last_sign_in_at, :timestamp

    add_column :users, :raw_app_meta_data, :json
    add_column :users, :raw_user_meta_data, :json

    add_column :users, :is_super_admin, :boolean
  end
end

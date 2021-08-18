class AddRefreshTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :refresh_tokens, id: :bigint do |t|
      t.binary :instance_id
      t.string :token
      t.string :user_id
      t.boolean :revoked

      t.timestamps
    end
  end
end

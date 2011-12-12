class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :identity_url

      t.timestamps
    end
  end
end

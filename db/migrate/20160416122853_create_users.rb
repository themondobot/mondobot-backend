class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :facebook_token
      t.string :mondo_token
   end
  end
end

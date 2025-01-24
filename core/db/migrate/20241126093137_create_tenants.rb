class CreateTenants < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_tenants, if_not_exists: true do |t|
      t.string :name

      t.timestamps
    end
    add_index :spree_tenants, :name, unique: true, if_not_exists: true
  end
end

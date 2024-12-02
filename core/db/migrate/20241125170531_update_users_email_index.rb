class UpdateUsersEmailIndex < ActiveRecord::Migration[7.2]
  def change
    remove_index :spree_users, :email, name: :email_idx_unique, if_exists: true
    add_index :spree_users, %i[tenant_id email], unique: true
  end
end

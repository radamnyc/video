class AddDescriptionToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :description, :text
  end
end

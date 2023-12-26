class AddDescriptionAmdNumberEmployeesToOrganization < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :description, :string
    add_column :organizations, :number_of_employees, :integer
  end
end

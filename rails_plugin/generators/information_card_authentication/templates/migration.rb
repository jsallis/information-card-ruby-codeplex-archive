class Create<%= user_model.camelize %>InformationCards < ActiveRecord::Migration
  def self.up
    create_table :<%= user_model.underscore %>_information_cards do |t|
      t.column :<%= user_model.underscore %>_id, :integer
      t.column :unique_id, :string, :limit => 50, :null => false
      t.column :ppid, :string, :limit => 50, :null => false
    end
  end

  def self.down
    drop_table :<%= user_model.underscore %>_information_cards
  end
end

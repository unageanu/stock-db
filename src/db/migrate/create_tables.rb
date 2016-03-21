begin
  ActiveRecord::Migration.create_table :users do |t|
    t.column :name       , :string
    t.column :nickname   , :string
    t.column :profile    , :text
    t.column :created_at , :datetime
    t.column :updated_at , :datetime
  end
rescue
end

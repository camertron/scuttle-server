class CreateAssociationCache < ActiveRecord::Migration
  def change
    create_table :association_caches do |t|
      t.column :owner, :string
      t.column :repo, :string
      t.column :sha1, :string
      t.column :association_json, :text
      t.timestamps
    end
  end
end

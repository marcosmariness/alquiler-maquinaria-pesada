class CreateArticulos < ActiveRecord::Migration[7.2]
  def change
    create_table :articulos do |t|
      t.string :nombre
      t.string :categoria
      t.decimal :precio_base_dia

      t.timestamps
    end
  end
end

class CreateAlquilerPeriodos < ActiveRecord::Migration[7.2]
  def change
    create_table :alquiler_periodos do |t|
      t.references :articulo, null: false, foreign_key: true
      t.date :fecha_inicio
      t.date :fecha_fin

      t.timestamps
    end
  end
end

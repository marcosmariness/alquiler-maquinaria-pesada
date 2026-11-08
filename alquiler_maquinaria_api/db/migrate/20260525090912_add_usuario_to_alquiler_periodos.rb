class AddUsuarioToAlquilerPeriodos < ActiveRecord::Migration[7.2]
  def change
    add_reference :alquiler_periodos, :usuario, null: false, foreign_key: true
  end
end

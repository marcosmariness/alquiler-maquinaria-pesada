class Articulo < ApplicationRecord
  has_many :alquiler_periodos, dependent: :destroy

  # Sobrescribimos el método JSON para adjuntar las fechas de ocupación automáticamente
  def as_json(options = {})
    super(include: { alquiler_periodos: { only: [:fecha_inicio, :fecha_fin] } })
  end
end

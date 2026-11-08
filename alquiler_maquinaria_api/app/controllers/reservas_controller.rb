class ReservasController < ApplicationController
  # GET /reservas
  def index
    # Traemos los periodos de alquiler incluyendo los datos del artículo asociado
    @alquileres = AlquilerPeriodo.includes(:articulo).all

    render json: @alquileres.as_json(include: { articulo: { only: [:nombre, :categoria] } })
  end

  # POST /reservas
  def create
    elementos = params[:elementos] || []
    tipo_envio = params[:tipo_envio] || "Estandar"
    
    # Recogemos el rango de fechas global de la reserva que nos envía Flutter
    fecha_desde = Date.parse(params[:fecha_inicio]) rescue Date.today
    fecha_hasta = Date.parse(params[:fecha_fin]) rescue Date.today + 1.day

    precio_total_alquiler = 0
    total_items = 0
    articulos_bloqueados = []

    # 1. Validar disponibilidad primero
    elementos.each do |item|
      articulo = Articulo.find_by(id: item[:articulo_id])
      next unless articulo

      # Buscamos si este artículo se solapa con las fechas solicitadas
      solapado = articulo.alquiler_periodos.where("fecha_inicio <= ? AND fecha_fin >= ?", fecha_hasta, fecha_desde).exists?
      
      if solapado
        articulos_bloqueados << articulo.nombre
      end
    end

    # Si hay algún conflicto de fechas, abortamos y avisamos a Flutter
    if articulos_bloqueados.any?
      render json: { 
        error: "Conflicto de disponibilidad", 
        detalles: "Los siguientes equipos ya están alquilados en esas fechas: #{articulos_bloqueados.join(', ')}" 
      }, status: :conflict
      return # Detiene la ejecución
    end

    # 2. Si todo está libre, procesamos el cobro (Composite + Decorator)
    elementos.each do |item|
      articulo = Articulo.find(item[:articulo_id])
      dias = (fecha_hasta - fecha_desde).to_i
      dias = 1 if dias <= 0
      
      precio_item = articulo.precio_base_dia * dias
      
      if item[:decoradores].present?
        item[:decoradores].each do |decorator|
          case decorator
          when "remolque" then precio_item += 40.0 * dias
          when "seguro_premium" then precio_item += 25.0 * dias
          when "operario" then precio_item += 100.0 * dias
          when "gps_agricola" then precio_item += 15.0 * dias
          end
        end
      end

      # 3. Bloqueamos las fechas en la base de datos
      articulo.alquiler_periodos.create!(fecha_inicio: fecha_desde, fecha_fin: fecha_hasta)

      precio_total_alquiler += precio_item
      total_items += 1
    end

    # 4. Patrón Strategy para el Envío
    coste_envio = case tipo_envio
                  when "Estandar" then 50.0 + (total_items * 10.0)
                  when "Urgente" then 120.0 + (total_items * 15.0)
                  when "Recogida" then 0.0
                  else 0.0
                  end

    render json: {
      precio_alquiler: precio_total_alquiler,
      coste_envio: coste_envio,
      gran_total: precio_total_alquiler + coste_envio,
      fecha_procesado: Time.now,
      mensaje: "¡Reserva confirmada y fechas bloqueadas con éxito!"
    }
  end
end

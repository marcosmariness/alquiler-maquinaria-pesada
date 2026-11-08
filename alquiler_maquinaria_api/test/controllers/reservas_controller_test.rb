require "test_helper"

# Clase de prueba para verificar las reglas de negocio, cálculo de costes (Decoradores y Strategy)
# y la lógica de conflictos/sobre-reservas en la API REST de Reservas (Rails)
class ReservasControllerTest < ActionDispatch::IntegrationTest
  
  # Método de configuración que carga artículos de las fixtures para realizar las pruebas
  setup do
    @tractor = articulos(:tractor)
    @maquina = articulos(:maquina)
    @accesorio = articulos(:accesorio)
  end

  # ==========================================
  # Caso de Prueba: Listar Reservas (READ - GET /reservas)
  # ==========================================
  test "deberia obtener el listado de reservas" do
    # 1. Petición GET al controlador de reservas
    get reservas_url, as: :json
    assert_response :success # Debe retornar HTTP 200 OK

    # 2. Verificaciones sobre la respuesta JSON:
    reservas_response = JSON.parse(response.body)
    assert_not_empty reservas_response
    
    # - Debería contener al menos la reserva inicial definida en la fixture (:reserva_tractor)
    assert_equal 1, reservas_response.length
    assert_equal @tractor.nombre, reservas_response.first["articulo"]["nombre"]
  end

  # ==========================================
  # Caso de Prueba: Creación de Reserva Exitosa y Matemáticas de Negocio
  # (POST /reservas con Decoradores y Estrategia de Envío Estándar)
  # ==========================================
  test "deberia crear reserva exitosamente con decoradores y envio estandar" do
    # 1. Comprueba que al terminar el POST, se hayan registrado 2 nuevos periodos de alquiler en la BD 
    # (uno para el tractor y otro para la máquina)
    assert_difference("AlquilerPeriodo.count", 2) do
      post reservas_url, params: {
        fecha_inicio: "2026-06-10",
        fecha_fin: "2026-06-12", # 2 días completos de alquiler (del 10 al 12)
        tipo_envio: "Estandar",   # Estrategia de envío
        elementos: [
          {
            articulo_id: @tractor.id,
            decoradores: ["remolque", "gps_agricola"] # Decoradores para Tractor
          },
          {
            articulo_id: @maquina.id,
            decoradores: ["seguro_premium"]          # Decorador para Máquina
          }
        ]
      }, as: :json
    end

    # 2. Comprueba que el servidor responda éxito (HTTP 200 OK)
    assert_response :success
    res = JSON.parse(response.body)

    # 3. VERIFICACIÓN DE LAS MATEMÁTICAS DEL NEGOCIO (Composite + Decorator + Strategy):
    #
    # >> Cálculo del Tractor (Decorado con Remolque y GPS):
    #    - Precio base tractor: 150.0/día * 2 días = 300.0€
    #    - Extra Remolque: 40.0/día * 2 días       = 80.0€
    #    - Extra GPS Agrícola: 15.0/día * 2 días   = 30.0€
    #    - Subtotal Tractor = 410.0€
    #
    # >> Cálculo de la Máquina (Decorada con Seguro Premium):
    #    - Precio base máquina: 250.0/día * 2 días = 500.0€
    #    - Extra Seguro Premium: 25.0/día * 2 días = 50.0€
    #    - Subtotal Máquina = 550.0€
    #
    # >> Subtotal Total del Alquiler = 410.0 + 550.0 = 960.0€
    assert_equal 960.0, res["precio_alquiler"].to_f

    # >> Gastos de Envío Estándar (Strategy):
    #    - Fórmula: 50.0€ (coste base) + (2 items * 10.0€) = 70.0€
    assert_equal 70.0, res["coste_envio"].to_f

    # >> Gran Total (Subtotal Alquiler + Envío):
    #    - Total = 960.0€ + 70.0€ = 1030.0€
    assert_equal 1030.0, res["gran_total"].to_f
    assert_match(/confirmada/, res["mensaje"])
  end

  # ==========================================
  # Caso de Prueba: Prevención de Conflictos de Fechas (Solapamiento)
  # ==========================================
  test "no deberia permitir reserva si hay solapamiento de fechas" do
    # Nota: En las fixtures, definimos que el tractor ya está alquilado del 2026-06-01 al 2026-06-05.
    # Si intentamos reservar ese mismo tractor del 2026-06-03 al 2026-06-07, existe un solapamiento directo.

    # 1. Comprueba que el número total de reservas en la BD NO cambie en absoluto (0 variaciones)
    assert_no_difference("AlquilerPeriodo.count") do
      post reservas_url, params: {
        fecha_inicio: "2026-06-03",
        fecha_fin: "2026-06-07",
        tipo_envio: "Recogida",
        elementos: [
          {
            articulo_id: @tractor.id,
            decoradores: []
          }
        ]
      }, as: :json
    end

    # 2. Comprueba que el servidor detenga la operación y retorne un error de conflicto (HTTP 409 Conflict)
    assert_response :conflict
    
    # 3. Comprueba que el cuerpo del JSON informe adecuadamente el tipo de error
    res = JSON.parse(response.body)
    assert_equal "Conflicto de disponibilidad", res["error"]
    assert_match(/ya están alquilados/, res["detalles"])
  end

  # ==========================================
  # Caso de Prueba: Intercambio de Estrategias de Envío (Urgente vs. Recogida)
  # ==========================================
  test "deberia calcular correctamente envio urgente y recogida en tienda" do
    # ---- ESTRATEGIA 1: Envío Urgente ----
    # 1. Realiza petición de alquiler de 1 artículo por 1 día seleccionando envío "Urgente"
    post reservas_url, params: {
      fecha_inicio: "2026-07-01",
      fecha_fin: "2026-07-02", 
      tipo_envio: "Urgente",
      elementos: [
        {
          articulo_id: @accesorio.id,
          decoradores: []
        }
      ]
    }, as: :json
    
    assert_response :success
    res_urgente = JSON.parse(response.body)
    
    # Verificación del envío urgente (Strategy):
    # - Fórmula: 120.0€ (coste base) + (1 item * 15.0€) = 135.0€
    assert_equal 135.0, res_urgente["coste_envio"].to_f


    # ---- ESTRATEGIA 2: Recogida en Tienda ----
    # 2. Realiza la misma petición pero seleccionando "Recogida" en tienda física
    post reservas_url, params: {
      fecha_inicio: "2026-08-01",
      fecha_fin: "2026-08-02", 
      tipo_envio: "Recogida",
      elementos: [
        {
          articulo_id: @accesorio.id,
          decoradores: []
        }
      ]
    }, as: :json
    
    assert_response :success
    res_recogida = JSON.parse(response.body)
    
    # Verificación de recogida (Strategy):
    # - Fórmula: Siempre es 0.0€
    assert_equal 0.0, res_recogida["coste_envio"].to_f
  end
end


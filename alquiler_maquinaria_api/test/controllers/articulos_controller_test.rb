require "test_helper"

# Clase de prueba para verificar las operaciones CRUD en la API REST de Artículos (Rails)
class ArticulosControllerTest < ActionDispatch::IntegrationTest
  
  # Método de configuración inicial que se ejecuta antes de cada test individual.
  # Aquí cargamos un artículo de prueba preconfigurado desde las fixtures (:tractor).
  setup do
    @articulo = articulos(:tractor)
  end

  # ==========================================
  # Operación: LEER (READ - GET /articulos)
  # ==========================================
  test "deberia obtener index de articulos" do
    # 1. Realiza una petición simulada GET a la ruta index de artículos pidiendo formato JSON
    get articulos_url, as: :json
    
    # 2. Comprueba que el backend haya respondido exitosamente (Código de estado HTTP 200 OK)
    assert_response :success

    # 3. Parsea el cuerpo de la respuesta JSON para poder analizarlo
    articulos_response = JSON.parse(response.body)
    
    # 4. Asertos de verificación:
    # - Comprueba que la lista de respuesta no venga vacía
    assert_not_empty articulos_response
    # - Comprueba que la cantidad de artículos devueltos coincida exactamente con la BD
    assert_equal Articulo.count, articulos_response.length
  end

  # ==========================================
  # Operación: CREAR (CREATE - POST /articulos)
  # ==========================================
  test "deberia crear articulo" do
    # 1. Comprueba que al finalizar la petición POST, el número total de artículos en la BD 
    # haya aumentado exactamente en 1 registro (+1)
    assert_difference("Articulo.count", 1) do
      post articulos_url, params: { 
        articulo: { 
          nombre: "Tractor John Deere Nuevo", 
          categoria: "Tractor", 
          precio_base_dia: 160.0 
        } 
      }, as: :json
    end

    # 2. Comprueba que el backend responda indicando que se ha creado con éxito (Código HTTP 201 Created)
    assert_response :created
    
    # 3. Parsea el JSON creado y comprueba que el nombre coincida con el enviado en los parámetros
    articulo_response = JSON.parse(response.body)
    assert_equal "Tractor John Deere Nuevo", articulo_response["nombre"]
  end

  # ==========================================
  # Operación: ACTUALIZAR (UPDATE - PATCH/PUT /articulos/:id)
  # ==========================================
  test "deberia actualizar articulo" do
    # 1. Realiza una petición PATCH para actualizar el nombre y el precio del tractor actual
    patch articulo_url(@articulo), params: { 
      articulo: { 
        nombre: "John Deere Modificado", 
        precio_base_dia: 195.0 
      } 
    }, as: :json

    # 2. Comprueba que la petición se haya procesado con éxito (Código HTTP 200 OK)
    assert_response :success
    
    # 3. Recarga el objeto de prueba directamente desde la Base de Datos para asegurar que se guardó
    @articulo.reload
    
    # 4. Asertos: Comprueba que los campos en la BD hayan tomado efectivamente los nuevos valores
    assert_equal "John Deere Modificado", @articulo.nombre
    assert_equal 195.0, @articulo.precio_base_dia.to_f
  end

  # ==========================================
  # Operación: BORRAR (DELETE - DELETE /articulos/:id)
  # ==========================================
  test "deberia borrar articulo" do
    # 1. Comprueba que al terminar el bloque, el total de artículos en la BD 
    # haya disminuido exactamente en 1 registro (-1)
    assert_difference("Articulo.count", -1) do
      delete articulo_url(@articulo), as: :json
    end

    # 2. Comprueba que el servidor responda con éxito (Código HTTP 200 OK)
    assert_response :success
  end
end


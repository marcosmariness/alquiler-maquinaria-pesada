class ArticulosController < ApplicationController
  # 1. LEER (GET /articulos)
  def index
    @articulos = Articulo.all
    render json: @articulos
  end

  # 2. CREAR (POST /articulos)
  def create
    @articulo = Articulo.new(articulo_params)
    if @articulo.save
      render json: @articulo, status: :created
    else
      render json: @articulo.errors, status: :unprocessable_entity
    end
  end

  # 3. ACTUALIZAR (PATCH/PUT /articulos/:id)
  def update
    @articulo = Articulo.find(params[:id])
    if @articulo.update(articulo_params)
      render json: @articulo
    else
      render json: @articulo.errors, status: :unprocessable_entity
    end
  end

  # 4. BORRAR (DELETE /articulos/:id)
  def destroy
    @articulo = Articulo.find(params[:id])
    if @articulo.destroy
      head :ok
    else
      render json: { error: "Error al eliminar el artículo" }, status: :unprocessable_entity
    end
  end

  private

  # Seguridad de Rails: Filtramos los campos permitidos del formulario
  def articulo_params
    params.require(:articulo).permit(:nombre, :categoria, :precio_base_dia)
  end
end

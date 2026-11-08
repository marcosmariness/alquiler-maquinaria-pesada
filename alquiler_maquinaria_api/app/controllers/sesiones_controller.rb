class SesionesController < ApplicationController
  # POST /login
  def create
    usuario = Usuario.find_by(email: params[:email])

    # Si el usuario existe y la contraseña es correcta
    if usuario && usuario.authenticate(params[:password])
      # Simulamos un token de acceso según su rol
      token_simulado = usuario.rol == "administrador" ? "Token gestor-secret-key" : "Token cliente-key"

      render json: {
        mensaje: "Inicio de sesión correcto",
        token: token_simulado,
        rol: usuario.rol,
        email: usuario.email
      }, status: :ok
    else
      render json: { error: "Email o contraseña incorrectos" }, status: :unauthorized
    end
  end
end

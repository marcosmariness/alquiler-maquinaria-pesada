class Usuario < ApplicationRecord
  has_secure_password

  # Validamos que el rol sea solo uno de los dos permitidos
  validates :rol, inclusion: { in: %w[cliente administrador] }
end

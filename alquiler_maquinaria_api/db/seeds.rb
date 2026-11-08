# Limpiamos la base de datos antes de empezar para no duplicar
Articulo.destroy_all

# Creamos Tractores
Articulo.create!(nombre: "John Deere 6R 150", categoria: "Tractor", precio_base_dia: 150.0)
Articulo.create!(nombre: "New Holland T7.210", categoria: "Tractor", precio_base_dia: 180.0)

# Creamos Maquinaria
Articulo.create!(nombre: "Hormigonera HT20", categoria: "Maquina", precio_base_dia: 45.0)
Articulo.create!(nombre: "Excavadora Caterpillar 320", categoria: "Maquina", precio_base_dia: 250.0)

# Creamos Accesorios Sueltos
Articulo.create!(nombre: "Pala Cargadora Frontal", categoria: "AccesorioSuelto", precio_base_dia: 30.0)
Articulo.create!(nombre: "Arado de Tres Surcos", categoria: "AccesorioSuelto", precio_base_dia: 25.0)

puts "🌱 ¡Base de datos alimentada con #{Articulo.count} artículos de prueba!"

# Creamos usuarios de prueba
Usuario.destroy_all
Usuario.create!(email: "admin@maquinaria.com", password: "admin123", rol: "administrador")
Usuario.create!(email: "user@gmail.com", password: "user123", rol: "cliente")

puts "👥 Usuarios de prueba creados!"

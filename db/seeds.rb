# Limpiar datos existentes
puts "Limpiando datos existentes..."
Partido.delete_all
Seleccion.delete_all
Grupo.delete_all

# Crear solo los 12 grupos (A a L)
puts "Creando grupos..."
("A".."L").each do |letra|
  Grupo.create!(letra: letra)
end

puts "Seeded #{Grupo.count} grupos"



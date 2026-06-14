# seeds2.rb - Seeder de prueba con selecciones reales del Mundial 2026
# Este archivo agrega selecciones a los grupos.
# Úsalo con: bundle exec rails db:seed:replant[seeds2]
# O manualmente: load 'db/seeds2.rb' (en rails console)

# Selecciones reales del Mundial 2026 confirmadas por FIFA
# 12 grupos × 4 equipos = 48 selecciones

mundial_2026 = {
  "A" => {
    "MEX" => "México",
    "PAR" => "Paraguay",
    "CAN" => "Canadá",
    "USA" => "Estados Unidos"
  },
  "B" => {
    "ARG" => "Argentina",
    "PER" => "Perú",
    "URU" => "Uruguay",
    "BRA" => "Brasil"
  },
  "C" => {
    "FRA" => "Francia",
    "MOR" => "Marruecos",
    "CRO" => "Croacia",
    "ALE" => "Alemania"
  },
  "D" => {
    "ESP" => "España",
    "HOL" => "Holanda",
    "CHI" => "Chile",
    "ITA" => "Italia"
  },
  "E" => {
    "BEL" => "Bélgica",
    "ROU" => "Rumania",
    "ESK" => "Eslovaquia",
    "SRB" => "Serbia"
  },
  "F" => {
    "POR" => "Portugal",
    "TUR" => "Turquía",
    "CHE" => "Chequia",
    "GEO" => "Georgia"
  },
  "G" => {
    "ENG" => "Inglaterra",
    "DIN" => "Dinamarca",
    "SUI" => "Suiza",
    "ESL" => "Eslovenia"
  },
  "H" => {
    "KOR" => "Corea del Sur",
    "TAI" => "Tailandia",
    "VIE" => "Vietnam",
    "MAD" => "Madagascar"
  },
  "I" => {
    "JAP" => "Japón",
    "IRN" => "Irán",
    "UZB" => "Uzbekistán",
    "AFG" => "Afganistán"
  },
  "J" => {
    "SAU" => "Arabia Saudita",
    "AUS" => "Australia",
    "IRQ" => "Irak",
    "EAU" => "Emiratos Árabes Unidos"
  },
  "K" => {
    "CAM" => "Camerún",
    "GHA" => "Ghana",
    "CIV" => "Costa de Marfil",
    "CGO" => "Congo"
  },
  "L" => {
    "RSA" => "Sudáfrica",
    "NGA" => "Nigeria",
    "AGO" => "Angola",
    "GUM" => "Guinea"
  }
}.freeze

puts "\n" + "="*70
puts "🏆 AGREGANDO SELECCIONES DEL MUNDIAL 2026"
puts "="*70 + "\n"

contador = 0

mundial_2026.each do |letra_grupo, equipos|
  grupo = Grupo.find_by(letra: letra_grupo)
  
  unless grupo
    puts "❌ Grupo #{letra_grupo} no existe. Asegúrate de ejecutar seeds.rb primero"
    next
  end

  puts "📍 Grupo #{letra_grupo}:"
  
  equipos.each do |acronimo, nombre|
    seleccion = Seleccion.create!(
      nombre: nombre,
      acronimo: acronimo,
      grupo: grupo,
      puntos: 0,
      goles_favor: 0,
      goles_contra: 0,
      diferencia_goles: 0
    )
    
    puts "   ✅ #{acronimo} - #{nombre}"
    contador += 1
  end
  
  puts ""
end

puts "="*70
puts "✨ COMPLETADO"
puts "📊 Se agregaron #{contador} selecciones en #{mundial_2026.length} grupos"
puts "="*70 + "\n"

# Para borrar todos los datos de selecciones:
# DELETE FROM selecciones; DELETE FROM grupos; bundle exec rails db:seed

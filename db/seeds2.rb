# seeds2.rb - Seeder de prueba con selecciones del Mundial 2026.
# Este archivo agrega o actualiza selecciones y carga banderas por ruta relativa.
# Úsalo con: load "db/seeds2.rb" desde rails console o runner.

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
    "MAR" => "Marruecos",
    "CRO" => "Croacia",
    "GER" => "Alemania"
  },
  "D" => {
    "ESP" => "España",
    "NED" => "Países Bajos",
    "CHI" => "Chile",
    "ITA" => "Italia"
  },
  "E" => {
    "BEL" => "Bélgica",
    "ROU" => "Rumania",
    "SVK" => "Eslovaquia",
    "SRB" => "Serbia"
  },
  "F" => {
    "POR" => "Portugal",
    "TUR" => "Turquía",
    "CZE" => "Chequia",
    "GEO" => "Georgia"
  },
  "G" => {
    "ENG" => "Inglaterra",
    "DEN" => "Dinamarca",
    "SUI" => "Suiza",
    "SVN" => "Eslovenia"
  },
  "H" => {
    "KOR" => "Corea del Sur",
    "THA" => "Tailandia",
    "VIE" => "Vietnam",
    "MAD" => "Madagascar"
  },
  "I" => {
    "JPN" => "Japón",
    "IRN" => "Irán",
    "UZB" => "Uzbekistán",
    "AFG" => "Afganistán"
  },
  "J" => {
    "KSA" => "Arabia Saudita",
    "AUS" => "Australia",
    "IRQ" => "Irak",
    "UAE" => "Emiratos Árabes Unidos"
  },
  "K" => {
    "CMR" => "Camerún",
    "GHA" => "Ghana",
    "CIV" => "Costa de Marfil",
    "CGO" => "Congo"
  },
  "L" => {
    "RSA" => "Sudáfrica",
    "NGA" => "Nigeria",
    "ANG" => "Angola",
    "GUI" => "Guinea"
  }
}.freeze

def ruta_bandera(acronimo)
  ruta_relativa = "flags/#{acronimo}.png"
  Rails.root.join(ruta_relativa).exist? ? ruta_relativa : nil
end

puts "\n" + ("=" * 70)
puts "AGREGANDO O ACTUALIZANDO SELECCIONES DEL MUNDIAL 2026"
puts "=" * 70

contador = 0

mundial_2026.each do |letra_grupo, equipos|
  grupo = Grupo.find_by(letra: letra_grupo)

  unless grupo
    puts "Grupo #{letra_grupo} no existe. Ejecuta seeds.rb primero."
    next
  end

  puts "Grupo #{letra_grupo}:"

  equipos.each do |acronimo, nombre|
    seleccion = Seleccion.find_by(acronimo: acronimo) ||
                Seleccion.find_by(nombre: nombre) ||
                Seleccion.new
    era_nueva = seleccion.new_record?

    if era_nueva && grupo.selecciones.count >= Grupo::MAXIMO_EQUIPOS
      puts "  Omitida: #{acronimo} - #{nombre} (Grupo #{letra_grupo} ya esta lleno)"
      next
    end

    if era_nueva
      seleccion.assign_attributes(
        nombre: nombre,
        acronimo: acronimo,
        grupo: grupo,
        bandera_url: ruta_bandera(acronimo),
        puntos: 0,
        goles_favor: 0,
        goles_contra: 0,
        diferencia_goles: 0
      )
    else
      seleccion.assign_attributes(
        nombre: nombre,
        grupo: grupo,
        bandera_url: ruta_bandera(seleccion.acronimo)
      )
    end

    seleccion.save!

    estado = era_nueva ? "Agregada" : "Actualizada"
    bandera = seleccion.bandera_url.present? ? seleccion.bandera_url : "sin bandera"
    puts "  #{estado}: #{acronimo} - #{nombre} (#{bandera})"
    contador += 1
  end

  puts ""
end

puts "=" * 70
puts "COMPLETADO"
puts "Se agregaron o actualizaron #{contador} selecciones en #{mundial_2026.length} grupos"
puts "=" * 70

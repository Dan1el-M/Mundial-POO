puts "Creando partidos de fase de grupos..."

# Eliminar partidos existentes de fase de grupos (opcional)
Partido.where(tipo_partido: "fase_grupos").destroy_all

numero_partido = 1

Grupo.order(:letra).each do |grupo|
  equipos = grupo.selecciones.to_a

  if equipos.size != 4
    puts "El grupo #{grupo.letra} no tiene exactamente 4 selecciones."
    next
  end

  # Fixture todos contra todos (6 partidos)
  enfrentamientos = [
    [equipos[0], equipos[1]],
    [equipos[2], equipos[3]],
    [equipos[0], equipos[2]],
    [equipos[1], equipos[3]],
    [equipos[0], equipos[3]],
    [equipos[1], equipos[2]]
  ]

  enfrentamientos.each do |local, visitante|
    goles_local = rand(0..5)
    goles_visitante = rand(0..5)

    partido = Partido.create!(
      numero_partido: numero_partido,
      estado: "programado",
      tipo_partido: "fase_grupos",
      seleccion_local: local,
      seleccion_visitante: visitante,
      grupo: grupo
    )

    partido.registrar_resultado!(
      goles_local,
      goles_visitante
    )

    puts "Partido #{numero_partido}: #{local.nombre} #{goles_local} - #{goles_visitante} #{visitante.nombre}"

    numero_partido += 1
  end
end

puts "Se crearon #{Partido.fase_grupos.count} partidos de fase de grupos."
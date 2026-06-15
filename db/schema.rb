# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_06_15_000000) do
  create_table "grupos", force: :cascade do |t|
    t.string "letra", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "torneo_id"
    t.index ["letra"], name: "index_grupos_on_letra", unique: true
    t.index ["torneo_id"], name: "index_grupos_on_torneo_id"
  end

  create_table "partidos", force: :cascade do |t|
    t.integer "numero_partido", null: false
    t.string "estado", default: "programado", null: false
    t.string "tipo_partido", null: false
    t.integer "torneo_id"
    t.integer "grupo_id"
    t.integer "seleccion_local_id", null: false
    t.integer "seleccion_visitante_id", null: false
    t.integer "ganador_id"
    t.integer "goles_local"
    t.integer "goles_visitante"
    t.integer "goles_penales_local"
    t.integer "goles_penales_visitante"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ganador_id"], name: "index_partidos_on_ganador_id"
    t.index ["grupo_id"], name: "index_partidos_on_grupo_id"
    t.index ["numero_partido"], name: "index_partidos_on_numero_partido"
    t.index ["seleccion_local_id"], name: "index_partidos_on_seleccion_local_id"
    t.index ["seleccion_visitante_id"], name: "index_partidos_on_seleccion_visitante_id"
    t.index ["tipo_partido", "estado"], name: "index_partidos_on_tipo_partido_and_estado"
    t.index ["torneo_id"], name: "index_partidos_on_torneo_id"
  end

  create_table "selecciones", force: :cascade do |t|
    t.string "nombre", null: false
    t.integer "grupo_id", null: false
    t.integer "puntos", default: 0, null: false
    t.integer "goles_favor", default: 0, null: false
    t.integer "goles_contra", default: 0, null: false
    t.integer "diferencia_goles", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "acronimo", limit: 3, null: false
    t.string "bandera_url"
    t.index ["acronimo"], name: "index_selecciones_on_acronimo", unique: true
    t.index ["grupo_id"], name: "index_selecciones_on_grupo_id"
    t.index ["nombre"], name: "index_selecciones_on_nombre", unique: true
  end

  create_table "torneos", force: :cascade do |t|
    t.string "nombre", null: false
    t.string "etapa_actual", default: "fase_grupos", null: false
    t.integer "campeon_id"
    t.integer "subcampeon_id"
    t.integer "tercero_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campeon_id"], name: "index_torneos_on_campeon_id"
    t.index ["etapa_actual"], name: "index_torneos_on_etapa_actual"
    t.index ["nombre"], name: "index_torneos_on_nombre", unique: true
    t.index ["subcampeon_id"], name: "index_torneos_on_subcampeon_id"
    t.index ["tercero_id"], name: "index_torneos_on_tercero_id"
  end

  add_foreign_key "grupos", "torneos"
  add_foreign_key "partidos", "grupos"
  add_foreign_key "partidos", "selecciones", column: "ganador_id"
  add_foreign_key "partidos", "selecciones", column: "seleccion_local_id"
  add_foreign_key "partidos", "selecciones", column: "seleccion_visitante_id"
  add_foreign_key "partidos", "torneos"
  add_foreign_key "selecciones", "grupos"
  add_foreign_key "torneos", "selecciones", column: "campeon_id"
  add_foreign_key "torneos", "selecciones", column: "subcampeon_id"
  add_foreign_key "torneos", "selecciones", column: "tercero_id"
end

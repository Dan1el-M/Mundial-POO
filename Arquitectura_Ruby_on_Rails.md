# Arquitectura del proyecto Ruby on Rails

Este proyecto utiliza **Ruby on Rails 7.1.6** con una arquitectura basada en el patrón **MVC**:

- **Modelo:** maneja los datos y las reglas del sistema.
- **Vista:** muestra la información al usuario.
- **Controlador:** recibe las solicitudes y conecta modelos con vistas.

---

## 1. Carpeta `app/`

Es la carpeta principal del código de la aplicación.

### `app/models/`

Contiene las clases que representan las entidades del sistema y sus reglas.

Ejemplos para este proyecto:

- `seleccion.rb`
- `grupo.rb`
- `partido.rb`

Aquí se definen atributos, validaciones, relaciones y métodos de negocio.

### `app/controllers/`

Contiene los controladores que reciben las acciones del usuario.

Ejemplos:

- registrar una selección;
- mostrar un grupo;
- actualizar un partido;
- eliminar un registro.

Los controladores consultan los modelos y seleccionan la vista que se debe mostrar.

### `app/views/`

Contiene las páginas HTML de la aplicación.

Cada controlador normalmente tiene una carpeta con sus vistas:

```text
app/views/selecciones/
app/views/grupos/
app/views/partidos/
```

Los archivos suelen terminar en `.html.erb`, lo que permite combinar HTML con Ruby.

### `app/helpers/`

Contiene métodos auxiliares utilizados principalmente en las vistas.

### `app/assets/`

Contiene recursos visuales:

- estilos CSS;
- imágenes;
- archivos relacionados con la presentación.

El archivo principal de estilos es:

```text
app/assets/stylesheets/application.css
```

### `app/jobs/`

Contiene tareas que pueden ejecutarse en segundo plano. Probablemente no será necesario al inicio del proyecto.

### `app/mailers/`

Se utiliza para enviar correos electrónicos. No es necesario salvo que el proyecto incorpore notificaciones por correo.

### `app/channels/`

Se utiliza para comunicación en tiempo real mediante WebSockets. No será necesario para las funciones básicas del Mundial.

---

## 2. Carpeta `config/`

Contiene la configuración general de Rails.

### `config/routes.rb`

Define las rutas de la aplicación.

Ejemplo:

```ruby
resources :selecciones
```

Esto crea rutas para registrar, mostrar, editar y eliminar selecciones.

### `config/database.yml`

Configura la conexión con la base de datos. Por defecto, el proyecto utiliza SQLite.

### `config/application.rb`

Contiene la configuración general de la aplicación.

### `config/environments/`

Configura los diferentes ambientes:

- `development.rb`: desarrollo local;
- `test.rb`: pruebas;
- `production.rb`: aplicación publicada.

### `config/initializers/`

Contiene configuraciones que se cargan al iniciar Rails. Normalmente no será necesario modificar esta carpeta al principio.

### `config/locales/`

Contiene archivos para traducciones y mensajes de la aplicación.

---

## 3. Carpeta `db/`

Contiene todo lo relacionado con la base de datos.

### `db/migrate/`

Aquí se guardan las migraciones, que crean o modifican tablas.

Ejemplo:

```text
create_selecciones.rb
```

### `db/schema.rb`

Representa la estructura actual de la base de datos. Rails lo genera automáticamente.

### `db/seeds.rb`

Permite insertar datos iniciales.

Puede utilizarse para registrar:

- los 12 grupos;
- las 48 selecciones;
- datos de prueba.

---

## 4. Carpeta `test/`

Contiene las pruebas automáticas.

Las carpetas principales son:

- `test/models/`: pruebas de modelos;
- `test/controllers/`: pruebas de controladores;
- `test/integration/`: pruebas de flujos completos;
- `test/system/`: pruebas de la interfaz.

---

## 5. Carpeta `bin/`

Contiene comandos ejecutables del proyecto.

Los más utilizados serán:

```powershell
bin/rails server
bin/rails console
bin/rails db:migrate
bin/rails test
```

En PowerShell también se puede utilizar:

```powershell
ruby bin/rails server
```

---

## 6. Carpeta `public/`

Contiene archivos públicos y páginas de error:

- `404.html`: página no encontrada;
- `422.html`: solicitud inválida;
- `500.html`: error interno.

---

## 7. Carpetas auxiliares

### `log/`

Guarda los registros de ejecución y errores de Rails.

### `tmp/`

Guarda archivos temporales, caché y procesos del servidor.

### `storage/`

Guarda archivos locales gestionados por Rails.

### `lib/`

Contiene módulos, clases o tareas adicionales que no pertenecen directamente al MVC.

### `vendor/`

Se utiliza para dependencias externas agregadas manualmente.

---

## 8. Archivos principales de la raíz

### `Gemfile`

Define las gemas o dependencias del proyecto.

Después de modificarlo se ejecuta:

```powershell
bundle install
```

### `Gemfile.lock`

Registra las versiones exactas de las gemas instaladas. Debe mantenerse en Git.

### `Rakefile`

Permite ejecutar tareas administrativas de Rails y Rake.

### `config.ru`

Se utiliza para iniciar la aplicación mediante servidores compatibles con Rack.

### `.ruby-version`

Indica la versión de Ruby esperada por el proyecto.

### `.gitignore`

Define los archivos que Git no debe subir.

### `Dockerfile`

Permite ejecutar la aplicación dentro de un contenedor Docker.

### `.dockerignore`

Indica qué archivos no deben copiarse al contenedor.

### `README.md`

Contiene la descripción, instalación y uso del proyecto.

---

## 9. Flujo básico de Rails

Una solicitud normalmente sigue este recorrido:

```text
Usuario
  ↓
Ruta
  ↓
Controlador
  ↓
Modelo
  ↓
Base de datos
  ↓
Controlador
  ↓
Vista
  ↓
Usuario
```

Ejemplo:

```text
GET /selecciones
```

1. Rails busca la ruta en `config/routes.rb`.
2. Ejecuta una acción del controlador.
3. El controlador consulta el modelo `Seleccion`.
4. El modelo obtiene los datos de la base de datos.
5. La vista muestra la lista de selecciones.

---

## 10. Carpetas más importantes para este proyecto

Durante el desarrollo, el equipo trabajará principalmente en:

```text
app/models/
app/controllers/
app/views/
config/routes.rb
db/migrate/
db/seeds.rb
test/
```

Las demás carpetas normalmente requieren pocos cambios.

---

## Nota sobre la instalación

La estructura del proyecto fue creada y `bundle install` terminó correctamente. Apareció una advertencia temporal de MSYS2 al descargar OpenSSL desde un servidor espejo, pero Bundler indicó:

```text
Bundle complete!
```

Por lo tanto, las gemas principales quedaron instaladas. El siguiente paso recomendado es comprobar el proyecto con:

```powershell
ruby bin/rails server
```

Luego se puede abrir:

```text
http://localhost:3000
```

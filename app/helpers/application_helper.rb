require "base64"

module ApplicationHelper
  def bandera_seleccion(seleccion, wrapper_class: "", image_class: "", text_class: "")
    acronimo = seleccion&.acronimo.presence || seleccion&.nombre.to_s.first(3).upcase.presence || "---"
    url = fuente_bandera(seleccion&.bandera_url)

    content_tag(:div, class: "relative overflow-hidden bg-white border border-outline-variant flex items-center justify-center #{wrapper_class}") do
      if url.present?
        image_tag(
          url,
          alt: "Bandera de #{seleccion.nombre}",
          class: "w-full h-full object-cover #{image_class}",
          onerror: "this.classList.add('hidden'); this.nextElementSibling.classList.remove('hidden');"
        ) +
          content_tag(:span, acronimo.upcase, class: "hidden font-black text-primary-container #{text_class}")
      else
        content_tag(:span, acronimo.upcase, class: "font-black text-primary-container #{text_class}")
      end
    end
  end

  private

  def fuente_bandera(valor)
    ruta = valor.to_s.strip
    return "" if ruta.blank?
    return ruta if ruta.start_with?("http://", "https://", "data:", "/")

    archivo = Rails.root.join(ruta)
    return "" unless archivo.exist? && archivo.file?

    extension = archivo.extname.delete(".").downcase
    tipo = extension == "svg" ? "svg+xml" : extension
    "data:image/#{tipo};base64,#{Base64.strict_encode64(archivo.binread)}"
  end
end

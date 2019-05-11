module DocusignTemplates
  class PdfWriter
    attr_reader :document, :recipients, :pdf

    def self.apply_fields!(document, recipients)
      PdfWriter.new(document, recipients).apply_fields!
    end

    def initialize(document, recipients)
      @document = document
      @recipients = recipients
      @pdf = Origami::PDF.read(document.path)
    end

    def apply_fields!
      render_pages
      output_pdf_data
    end

    private

    def render_pages
      pdf.pages.each_with_index do |page, page_index|
        render_page(page, page_index)
      end
    end

    def render_page(page, page_index)
      add_page_fonts(page)
      stream = Origami::ContentStream.new

      each_required_page_field(page_index) do |field|
        rect_coords = to_page_coordinate(page, field.x, field.y, field.height)
        stream.draw_rectangle(rect_coords[:x], rect_coords[:y], field.width, field.height, stroke: false, fill: true, fill_color: Origami::Graphics::Color::RGB.new(255,0,0))

        field.radios.each do |radio|
          rect_coords = to_page_coordinate(page, radio.x, radio.y, 13)
          stream.draw_rectangle(rect_coords[:x], rect_coords[:y], 13, 13, stroke: false, fill: true, fill_color: Origami::Graphics::Color::RGB.new(255,0,0))
        end
      end

      # stream.write("XYZ THIS IS A TEST", x: 15, y: 55, size: 9)
      page.Contents << stream
    end

    def each_required_page_field(page_index)
      recipients.each do |recipient|
        recipient.fields_for_document_page(document, page_index).each do |field|
          yield field unless field.disabled?
        end
      end
    end

    def add_page_fonts(page)
      page.add_font(Origami::Font::Type1::Standard::Courier.new.pre_build)
    end

    def to_page_coordinate(page, x, y, height)
      page_height = page.MediaBox.value[3] - page.MediaBox.value[1]
      new_x = x + page.MediaBox[0]
      new_y = page_height - y + page.MediaBox[1] - height
      { x: new_x, y: new_y }
    end

    # getting PDF data in-memory is currently a private method
    def output_pdf_data
      options = {
        delinearize: true,
        recompile: true,
        decrypt: false
      }

      pdf.send(:compile, options)
      pdf.send(:output, options)
    end
  end
end

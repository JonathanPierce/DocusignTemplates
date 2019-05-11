module DocusignTemplates
  class PdfWriter
    attr_reader :document, :recipients, :pdf

    BOX_COLOR = Origami::Graphics::Color::RGB.new(30, 30, 30)

    FONT_COLORS = {
      black: Origami::Graphics::Color::RGB.new(0, 0, 0),
      brightblue: Origami::Graphics::Color::RGB.new(30, 30, 30),
      brightred: Origami::Graphics::Color::RGB.new(219, 17, 17),
      darkgreen: Origami::Graphics::Color::RGB.new(18, 130, 21),
      darkred: Origami::Graphics::Color::RGB.new(114, 16, 16),
      gold: Origami::Graphics::Color::RGB.new(237, 187, 9),
      green: Origami::Graphics::Color::RGB.new(23, 170, 26),
      navyblue: Origami::Graphics::Color::RGB.new(41, 66, 112),
      purple: Origami::Graphics::Color::RGB.new(130, 11, 193),
      white: Origami::Graphics::Color::RGB.new(255, 255, 255)
    }

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
        if field.is_checkbox?
          draw_checkbox(page, stream, field)
        elsif field.is_radio_group?
          draw_radio_group(page, stream, field)
        elsif field.is_text?
          draw_text(page, stream, field)
        end
      end

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

    # all coordinates from templates are slightly off in the same way
    def corrected_box_coordinate(page, x, y, height)
      coordinate = to_page_coordinate(page, x, y, height)
      { x: coordinate[:x] + 3, y: coordinate[:y] - 1}
    end

    def draw_checkbox(page, stream, field)
      return unless field.selected?

      top_left = corrected_box_coordinate(page, field.x, field.y, field.height)

      offset = 2
      line_width = 2
      half_line_width = line_width / 2

      corners = [
        [offset + half_line_width, offset + half_line_width ],
        [field.width - offset - half_line_width, offset + half_line_width],
        [offset + half_line_width, field.height - offset - half_line_width],
        [field.width - offset - half_line_width, field.height - offset - half_line_width]
      ].map do |coords|
        x, y = coords
        [top_left[:x] + x, top_left[:y] + y]
      end

      [
        [corners[0], corners[3]],
        [corners[1], corners[2]]
      ].each do |cross_points|
        start, finish = cross_points

        stream.draw_line(start, finish, {
          stroke: true,
          line_width: 3,
          line_cap: Origami::Graphics::LineCapStyle::ROUND_CAP,
          line_join: Origami::Graphics::LineJoinStyle::ROUND_JOIN,
          stroke_color: BOX_COLOR
        })
      end
    end

    def draw_radio_group(page, stream, field)
      field.radios.each do |radio|
        draw_radio(page, stream, radio)
      end
    end

    def draw_radio(page, stream, radio)
      return unless radio.selected?

      radio_size = 13
      half_radio_size = radio_size / 2
      top_left = corrected_box_coordinate(page, radio.x, radio.y, radio_size)
      midpoint = [top_left[:x] + half_radio_size, top_left[:y] + half_radio_size]

      stream.draw_line(midpoint, midpoint, {
        stroke: true,
        line_width: half_radio_size * 1.5,
        line_cap: Origami::Graphics::LineCapStyle::ROUND_CAP,
        line_join: Origami::Graphics::LineJoinStyle::ROUND_JOIN,
        stroke_color: BOX_COLOR
      })
    end

    def draw_text(page, stream, field)
      return if field.value.empty?

      # PDF renders text from bottom-left, docusign from top-left
      corrected_x = field.x + 2
      corrected_y = field.y - (field.height / 4)

      options = corrected_box_coordinate(page, corrected_x, corrected_y, field.height).merge(
        size: field.font_size,
        color: get_font_color(field)
      )

      stream.write(field.value, options)
    end

    def get_font_color(field)
      FONT_COLORS[field.font_color] || FONT_COLORS[:black]
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

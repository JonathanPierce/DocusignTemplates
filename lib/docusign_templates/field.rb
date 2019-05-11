module DocusignTemplates
  class Field
    module FieldTypes
      TEXT = "text"
      CHECKBOX = "checkbox"
      RADIO_GROUP = "radiogroup"
    end

    attr_reader :data
    attr_accessor :disabled

    def initialize(data)
      @data = data.deep_dup
      @disabled = false
    end

    def merge!(other_data)
      data.merge!(other_data)
    end

    def disabled?
      disabled
    end

    def label
      data[:group_name] || data[:tab_label]
    end

    def x
      data[:x_position].to_i
    end

    def y
      data[:y_position].to_i
    end

    def width
      data[:width].to_i
    end

    def height
      data[:height].to_i
    end

    def font_color
      data[:font_color]
    end

    def font_size
      data[:font_size]
    end

    def recipient_id
      data[:recipient_id]
    end

    def document_id
      data[:document_id]
    end

    def page_number
      if is_radio_group?
        radios.first.page_number
      else
        data[:page_number].to_i
      end
    end

    def page_index
      page_number - 1
    end

    def is_radio_group?
      data[:tab_type] == FieldTypes::RADIO_GROUP
    end

    def is_checkbox?
      data[:tab_type] == FieldTypes::CHECKBOX
    end

    def is_text?
      data[:tab_type] == FieldTypes::TEXT
    end

    def radios
      return [] unless is_radio_group?

      @radios ||= data[:radios].map do |radio|
        Field.new(radio)
      end
    end
  end
end

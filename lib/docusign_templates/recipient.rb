module DocusignTemplates
  class Recipient
    attr_reader :data

    def initialize(data)
      @data = data.deep_dup.except(:tabs, :pdf_fields)
      @fields = parse_fields_or_tabs(data[:pdf_fields])
      @tabs = parse_fields_or_tabs(data[:tabs])
    end

    def merge!(other_data)
      @data.merge!(other_data)
    end

    def role_name
      data[:role_name]
    end

    def fields_for_document(document)
      flatten_fields(@fields).select do |field|
        field.document_id == document.document_id
      end
    end

    def fields_for_document_page(document, page_index)
      fields_for_document(document).select do |field|
        field.page_index == page_index
      end
    end

    def tabs_for_document(document)
      flatten_fields(@tabs).select do |tab|
        tab.document_id == document.document_id
      end
    end

    private

    def flatten_fields(fields)
      fields.values.flatten
    end

    def parse_fields_or_tabs(fields_or_tabs)
      result = {}

      fields_or_tabs.each do |type, type_fields|
        result[type] = type_fields.map do |field|
          Field.new(field)
        end
      end

      result
    end
  end
end

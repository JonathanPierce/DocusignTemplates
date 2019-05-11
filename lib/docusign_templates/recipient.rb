module DocusignTemplates
  class Recipient
    attr_reader :data

    def initialize(data)
      @data = data.deep_dup.except(:tabs, :pdf_fields)
      @fields = parse_fields_or_tabs(data[:pdf_fields])
      @tabs = parse_fields_or_tabs(data[:tabs])
    end

    def fields_for_document(document)
      @fields.select do |field|
        field.document_id == document.document_id
      end
    end

    def tabs_for_document(document)
      @tabs.select do |tab|
        tab.document_id == document.document_id
      end
    end

    private

    def parse_fields_or_tabs(fields_or_tabs)
      result = {}

      fields_or_tabs.each do |type, type_fields|
        result[:type] = type_fields.map do |field|
          Field.new(field)
        end
      end

      result
    end
  end
end

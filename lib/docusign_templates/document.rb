module DocusignTemplates
  class Document
    attr_reader :data

    def initialize(data)
      @data = data.deep_dup
    end

    def document_id
      data[:document_id]
    end

    def fields_for_recipient(recipient)
      recipient.fields_for_document(self)
    end

    def tabs_for_recipient(recipient)
      recipient.tabs_for_document(self)
    end

    def blank_pdf_data
      @pdf_data ||= File.read(data[:path])
    end

    def to_pdf
      # TODO
    end

    def save_pdf!(path)
      # TODO
    end
  end
end

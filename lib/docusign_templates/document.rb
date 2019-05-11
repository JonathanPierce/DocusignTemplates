module DocusignTemplates
  class Document
    attr_reader :data, :base_directory

    def initialize(data, base_directory)
      @data = data.deep_dup
      @base_directory = base_directory
    end

    def merge!(other_data)
      @data.merge!(other_data)
    end

    def path
      "#{base_directory}/#{@data[:path]}"
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
      @blank_pdf_data ||= File.read(path)
    end

    def is_static?(recipients)
      recipients.all? do |recipient|
        # can use static PDF if only tabs
        fields_for_recipient(recipient).empty?
      end
    end

    def to_pdf(recipients)
      if is_static?(recipients)
        blank_pdf_data
      else
        apply_fields_to_pdf(recipients)
      end
    end

    def save_pdf!(path, recipients)
      File.open(path, "wb") do |file|
        file.write to_pdf(recipients)
      end
    end

    private

    def apply_fields_to_pdf(recipients)
      PdfWriter.apply_fields!(self, recipients)
    end
  end
end

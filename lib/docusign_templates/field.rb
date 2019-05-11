module DocusignTemplates
  class Field
    attr_reader :data
    attr_accessor :disabled

    def initialize(data)
      @data = data.deep_dup
      @disabled = false
    end

    def recipient_id
      data[:recipient_id]
    end

    def document_id
      data[:document_id]
    end
  end
end

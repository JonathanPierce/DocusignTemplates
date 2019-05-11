module DocusignTemplates
  class Template
    attr_reader :data

    def initialize(base_directory, template_name)
      @base_directory = base_directory
      @template_name = template_name
      @data = read_template

      @recipients = data[:recipients].map do |recipient|
        Recipient.new(recipient)
      end

      @documents = data[:documents].map do |document|
        Document.new(document)
      end
    end

    def recipients_for_roles(roles)
    end

    def to_composite_template(recipients, document_options = {})
      # TODO
    end

    private

    def read_template
      YAML.load(
        File.read("#{@base_directory}/#{@template_name}.yml")
      ).deep_symbolize_keys
    end
  end
end

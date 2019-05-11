module DocusignTemplates
  class Template
    attr_reader :base_directory, :template_name, :data, :recipients, :documents

    def initialize(base_directory, template_name)
      @base_directory = File.expand_path(base_directory)
      @template_name = template_name
      @data = read_template

      @recipients = parse_recipients
      @documents = parse_documents
    end

    def signers
      recipients[:signers]
    end

    def recipients_for_roles(roles)
      result = []

      recipients.each do |type, type_recipients|
        type_recipients.each do |recipient|
          result << recipient if roles.include?(recipient.role_name)
        end
      end

      result
    end

    def for_each_recipient_tab(recipients)
      recipients.each do |recipient|
        recipient.tabs.each do |type, type_values|
          type_values.map do |tab|
            yield tab
          end
        end

        recipient.fields.each do |type, type_values|
          type_values.map do |field|
            yield field
          end
        end
      end
    end

    def to_composite_template(recipients, document_options = {})
      # TODO
    end

    private

    def parse_recipients
      results = {}

      data[:recipients].each do |type, type_recipients|
        results[type] = type_recipients.map do |recipient|
          Recipient.new(recipient)
        end
      end

      results
    end

    def parse_documents
      data[:documents].map do |document|
        Document.new(document, base_directory)
      end
    end

    def read_template
      YAML.load(
        File.read("#{@base_directory}/#{@template_name}.yml")
      ).deep_symbolize_keys
    end
  end
end

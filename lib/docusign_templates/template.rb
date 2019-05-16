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

    def template_options
      data[:template_options]
    end

    def signers
      recipients[:signers] || []
    end

    # returns an array of all recipients matching on the the roles, regardless of type
    def recipients_for_roles(roles)
      result = []

      recipients.each do |type, type_recipients|
        type_recipients.each do |recipient|
          result << recipient if roles.include?(recipient.role_name)
        end
      end

      result
    end

    def recipient_for_role(role)
      recipients.each do |type, type_recipients|
        type_recipients.each do |recipient|
          return recipient if recipient.role_name == role
        end
      end

      nil
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

    # NOTE: Recipients should be an object mapping <string,Recipient[]>, where the
    # string is the recipient type (eg: "signers")
    def as_composite_template_entry(recipients, sequence)
      all_type_recipients = recipients.values.flatten

      {
        sequence: sequence.to_s,
        recipients: recipients_for_composite_template_entry(recipients),
        documents: documents.map do |document|
          document.as_composite_template_entry(all_type_recipients)
        end
      }
    end

    # Generates the tempalte in new process, bypassing the GIL
    # Allows for a speedup when run in a thread in CRuby
    def async_as_composite_template_entry(recipients, sequence)
      reader, writer = IO.pipe

      pid = fork do
        reader.close

        writer.write(
          JSON.dump(as_composite_template_entry(recipients, sequence))
        )

        writer.close
        Kernel.exit!
      end

      writer.close
      result = JSON.parse(reader.read)

      Process.wait(pid)
      reader.close
      result
    end

    private

    def recipients_for_composite_template_entry(recipients)
      return nil if recipients.empty?

      result = {}

      recipients.each do |type, type_recipients|
        result[type] = type_recipients.map(&:as_composite_template_entry)
      end

      result
    end

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

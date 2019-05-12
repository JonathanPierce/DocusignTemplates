module DocusignTemplates
  class Converter
    attr_reader :path, :template_json

    FIELD_TYPES = [
      :checkbox_tabs,
      :radio_group_tabs,
      :text_tabs
    ]

    TAB_TYPES = [
      :approve_tabs,
      :company_tabs,
      :date_signed_tabs,
      :date_tabs,
      :decline_tabs,
      :email_address_tabs,
      :email_tabs,
      :envelope_id_tabs,
      :first_name_tabs,
      :formula_tabs,
      :full_name_tabs,
      :initial_here_tabs,
      :last_name_tabs,
      :list_tabs,
      :notarize_tabs,
      :note_tabs,
      :number_tabs,
      :signer_attachment_tabs,
      :sign_here_tabs,
      :ssn_tabs,
      :tab_groups,
      :title_tabs,
      :view_tabs,
      :zip_tabs
    ]

    def self.camelize(thing)
      if thing.is_a?(Hash)
        converted = {}

        thing.each do |key, value|
          converted[key.camelize(:lower)] = camelize(value)
        end

        converted
      elsif thing.is_a?(Array)
        thing.map { |value| camelize(value) }
      else
        thing
      end
    end

    def self.underscoreize(thing)
      if thing.is_a?(Hash)
        converted = {}

        thing.each do |key, value|
          converted[key.underscore] = underscoreize(value)
        end

        converted
      elsif thing.is_a?(Array)
        thing.map { |value| underscoreize(value) }
      else
        thing
      end
    end

    def self.convert!(path, output_directory, template_name)
      Converter.new(path).convert!(output_directory, template_name)
    end

    def initialize(path)
      @path = path
      @template_json = read_template_json
    end

    def convert!(output_directory, template_name)
      converted_template = {
        name: template_name,
        template_options: template_json.except(
          :documents, :recipients
        ),
        documents: output_documents(output_directory, template_name),
        recipients: output_recipients
      }

      output_path = "#{output_directory}/#{template_name}.yml"
      File.write(output_path, YAML.dump(converted_template.deep_stringify_keys))

      Template.new(output_directory, template_name)
    end

    private

    def read_template_json
      json_data = JSON.parse(File.read(path))
      Converter.underscoreize(json_data).deep_symbolize_keys
    end

    def output_documents(output_directory, template_name)
      template_json[:documents].map.with_index do |document, index|
        index_part = "_#{index}"
        file_name = "#{template_name}#{index_part}.pdf"
        output_path = "#{output_directory}/#{file_name}"

        File.open(output_path, "wb") do |file|
          file.write Base64.decode64(document.delete(:document_base64))
        end

        document.merge(path: file_name)
      end
    end

    def output_recipients
      recipients = {}

      template_json[:recipients].each do |type, type_recipients|
        next unless type_recipients.is_a?(Array)
        next if type_recipients.empty?

        recipients[type] = type_recipients.map do |recipient|
          output_recipient(recipient)
        end
      end

      recipients
    end

    def output_recipient(recipient)
      recipient.except(:tabs).merge(
        pdf_fields: output_pdf_fields(recipient),
        tabs: output_tabs(recipient)
      )
    end

    def output_pdf_fields(recipient)
      if recipient[:tabs]
        recipient[:tabs].slice(*FIELD_TYPES)
      else
        {}
      end
    end

    def output_tabs(recipient)
      if recipient[:tabs]
        recipient[:tabs].slice(*TAB_TYPES)
      else
        {}
      end
    end
  end
end

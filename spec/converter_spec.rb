module DocusignTemplates
  RSpec.describe Converter do
    describe ".camelize" do
      it "deeply camelizes the hash" do
        input = {
          camel_case: {
            deep_keys: true,
            array: [
              { array_entry: 123 },
              {
                deep_entry: {
                  test_key: "derp"
                }
              }
            ]
          },
          testing_stuff: 123
        }.deep_stringify_keys

        expect(Converter.camelize(input)).to eq({
          camelCase: {
            deepKeys: true,
            array: [
              { arrayEntry: 123 },
              {
                deepEntry: {
                  testKey: "derp"
                }
              }
            ]
          },
          testingStuff: 123
        }.deep_stringify_keys)
      end
    end

    describe ".underscoreize" do
      it "deeply underscorizes the hash" do
        input = {
          camelCase: {
            deepKeys: true,
            array: [
              { arrayEntry: 123 },
              {
                deepEntry: {
                  testKey: "derp"
                }
              }
            ]
          },
          testingStuff: 123
        }.deep_stringify_keys

        expect(Converter.underscoreize(input)).to eq({
          camel_case: {
            deep_keys: true,
            array: [
              { array_entry: 123 },
              {
                deep_entry: {
                  test_key: "derp"
                }
              }
            ]
          },
          testing_stuff: 123
        }.deep_stringify_keys)
      end
    end

    describe ".convert!" do
      let(:path) { "some/path/to.json" }
      let(:output_directory) { "output/directory" }
      let(:template_name) { "tempalte_name" }

      it "creates a new converter and then converts" do
        converted_template = instance_double(Template)
        converter = instance_double(Converter)

        expect(Converter)
          .to receive(:new)
          .with(path)
          .and_return(converter)

        expect(converter)
          .to receive(:convert!)
          .with(output_directory, template_name)
          .and_return(converted_template)

        expect(
          Converter.convert!(path, output_directory, template_name)
        ).to be(converted_template)
      end
    end

    describe "initialize" do
      let(:template_json) do
        {
          camelCase: "yes",
          deepKeys: {
            stillCamelCase: true
          },
          array: [1,2,3]
        }.deep_stringify_keys
      end

      let(:path) { "path/to/some.json" }

      before do
        allow(File)
          .to receive(:read)
          .and_return(JSON.dump(template_json))
      end

      it "sets the path" do
        converter = Converter.new(path)
        expect(converter.path).to eq(path)
      end

      it "reads, underscoreizes, and sets the template JSON" do
        expect(File).to receive(:read).with(path)

        converter = Converter.new(path)

        expect(converter.template_json).to eq(
          Converter.underscoreize(template_json).deep_symbolize_keys
        )
      end
    end

    describe "convert!" do
      let(:first_doc_data) { "first doc data!" }
      let(:second_doc_data) { "second doc data!" }

      def create_tabs(types)
        result = {}

        types.each do |type|
          result[:type] = 3.times.map do |index|
            { label: "#{type.to_s}_tab_#{index}" }
          end
        end

        result
      end

      let(:template_json) do
        {
          templateId: "some-template-id",
          otherTemplateProperty: "other property",
          recipients: {
            signers: [
              {
                id: "1",
                roleName: "primary",
                tabs: create_tabs(Converter::FIELD_TYPES).merge(
                  create_tabs(Converter::TAB_TYPES)
                )
              },
              {
                id: "2",
                roleName: "secondary",
                tabs: create_tabs(Converter::FIELD_TYPES).merge(
                  create_tabs(Converter::TAB_TYPES)
                )
              }
            ],
            carbonCopies: [
              {
                id: "3",
                roleName: "carbon"
              }
            ]
          },
          documents: [
            {
              name: "First Document.pdf",
              property: "thing",
              document_base64: Base64.encode64(first_doc_data)
            },
            {
              name: "Second Document.pdf",
              property: "derp",
              document_base64: Base64.encode64(second_doc_data)
            }
          ]
        }
      end

      let(:path) { "path/to/some.json" }

      let(:file) do
        result = instance_double(File)
        allow(result).to receive(:write).and_return(nil)
        result
      end

      let(:dumped_yaml) do
        {}
      end

      let(:output_directory) { "output/directory" }
      let(:template_name) { "template_name" }
      let(:converter) { Converter.new(path) }

      let(:template) { instance_double(Template) }

      before do
        allow(File).to receive(:read) do
          JSON.dump(template_json)
        end

        allow(File).to receive(:write).and_return(nil)

        allow(File).to receive(:open).and_yield(file)

        allow(YAML).to receive(:dump) do |yaml|
          dumped_yaml.merge!(yaml).deep_symbolize_keys!
        end

        allow(Template).to receive(:new).and_return(template)
      end

      it "returns a matching template" do
        expect(Template).to receive(:new).with(output_directory, template_name)
        result = converter.convert!(output_directory, template_name)
        expect(result).to be(template)
      end

      context "YAML output" do
        it "writes YAML to the correct path" do
          expect(File).to receive(:write).with(
            "#{output_directory}/#{template_name}.yml",
            dumped_yaml
          )

          converter.convert!(output_directory, template_name)
        end

        it "sets the template name" do
          converter.convert!(output_directory, template_name)

          expect(dumped_yaml[:name]).to eq(template_name)
        end

        it "sets the template options" do
          converter.convert!(output_directory, template_name)

          expect(dumped_yaml[:template_options]).to eq(
            converter.template_json.except(:documents, :recipients)
          )
        end

        context "recipient output" do
          it "returns an empty object if there are no recipients" do
            template_json[:recipients] = nil

            converter.convert!(output_directory, template_name)

            expect(dumped_yaml[:recipients]).to eq({})
          end

          it "ignores empty recipient type arrays" do
            template_json[:recipients] = {
              signers: [],
              carbonCopies: []
            }

            converter.convert!(output_directory, template_name)

            expect(dumped_yaml[:recipients]).to eq({})
          end

          it "sets tabs and pdf fields to empty objects if none" do
            template_json[:recipients].each do |type, type_recipients|
              type_recipients.each do |recipient|
                recipient[:tabs] = nil
              end
            end

            converter.convert!(output_directory, template_name)

            dumped_yaml[:recipients].each do |type, type_recipients|
              type_recipients.each do |recipient|
                expect(recipient[:pdf_fields]).to eq({})
                expect(recipient[:tabs]).to eq({})
              end
            end
          end

          it "splits tabs between pdf_fields and tabs based on type" do
            converter.convert!(output_directory, template_name)

            dumped_yaml[:recipients].each do |type, type_recipients|
              type_recipients.each_with_index do |recipient, index|
                source_recipient = converter.template_json[:recipients][type][index]
                next unless source_recipient[:tabs]

                expect(recipient[:pdf_fields]).to eq(
                  source_recipient[:tabs].slice(*Converter::FIELD_TYPES)
                )
                expect(recipient[:tabs]).to eq(
                  source_recipient[:tabs].slice(*Converter::TAB_TYPES)
                )
              end
            end
          end
        end

        context "document_output" do
          it "outputs each document to a file" do
            converter.template_json[:documents].each_with_index do |document, index|
              file_name = "#{template_name}_#{index}.pdf"
              expected_path = "#{output_directory}/#{file_name}"

              expect(File).to receive(:open).with(expected_path, "wb")
              expect(file).to receive(:write).with(
                Base64.decode64(document[:document_base64])
              )
            end

            converter.convert!(output_directory, template_name)
          end

          it "replaces the document_base64 with the path" do
            converter.convert!(output_directory, template_name)

            dumped_yaml[:documents].each_with_index do |document, index|
              source = converter.template_json[:documents][index]
              file_name = "#{template_name}_#{index}.pdf"

              expect(document).to eq(
                source.except(:document_base64).merge(path: file_name)
              )
            end
          end
        end
      end
    end
  end
end

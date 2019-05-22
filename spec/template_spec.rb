module DocusignTemplates
  RSpec.describe Template do
    let(:base_directory) { "path/to/templates" }
    let(:template_name) { "template_name" }

    let(:signers) do
      2.times.map do |index|
        {
          recipient_id: (index + 1).to_s,
          role_name: "signer_#{index}",
          pdf_fields: {},
          tabs: {}
        }
      end
    end

    let(:recipients) do
      {
        signers: signers,
        carbon_copies: [
          {
            recipient_id: "123",
            role_name: "test",
            pdf_fields: {},
            tabs: {}
          }
        ]
      }
    end

    let(:document) do
      {
        document_id: "42",
        path: "some_path.pdf"
      }
    end

    let(:data) do
      {
        name: template_name,
        template_options: {
          some: "template",
          options: true
        },
        recipients: recipients,
        documents: [document]
      }
    end

    let(:template) { Template.new(base_directory, template_name) }

    before do
      allow(File).to receive(:read).and_return(data.to_json)
      allow(YAML).to receive(:load).and_return(data.deep_stringify_keys)
    end

    describe "initialize" do
      it "sets base_directory and template_name" do
        expect(template.base_directory).to eq(File.expand_path(base_directory))
        expect(template.template_name).to eq(template_name)
      end

      it "reads the template and sets the data" do
        expect(File).to receive(:read).with(
          "#{File.expand_path(base_directory)}/#{template_name}.yml"
        )
        expect(YAML).to receive(:load).with(data.to_json)
        expect(template.data).to eq(data)
      end

      it "parses all recipients" do
        recipients.each do |type, type_recipients|
          type_recipients.each_with_index do |recipient, index|
            match = template.recipients[type][index]
            expect(match).to be_a(Recipient)
            expect(match.data).to eq(recipient.except(:pdf_fields, :tabs))
          end
        end
      end

      it "parses all documents" do
        data[:documents].each_with_index do |document, index|
          match = template.documents[index]
          expect(match).to be_a(Document)
          expect(match.data).to eq(document)
        end
      end
    end

    describe "template_options" do
      it "returns template_options from data" do
        expect(template.template_options).to eq(data[:template_options])
      end
    end

    describe "signers" do
      it "returns signers from recipients" do
        expect(template.signers).to eq(template.recipients[:signers])
      end
    end

    describe "recipients_for_roles" do
      it "returns an array of recipients matching the given roles" do
        roles = ["signer_1", "test"]

        expect(template.recipients_for_roles(roles)).to eq([
          template.signers.last,
          template.recipients[:carbon_copies].first
        ])
      end
    end

    describe "recipient_for_role" do
      it "returns the first recipient matching the given role" do
        expect(template.recipient_for_role("test")).to eq(
          template.recipients[:carbon_copies].first
        )
      end

      it "returns nil if not found" do
        expect(template.recipient_for_role("fake")).to be(nil)
      end
    end

    describe "for_each_recipient_tab" do
      def make_fields
        3.times.map do
          instance_double(Field)
        end
      end

      it "yields every tab and field for each recipient" do
        recipient = template.signers.first

        fields = {
          kind: make_fields,
          other_kind: make_fields
        }

        tabs = {
          type: make_fields,
          other_type: make_fields
        }

        allow(recipient).to receive(:fields).and_return(fields)
        allow(recipient).to receive(:tabs).and_return(tabs)

        recipients = [recipient]

        yielded_fields = []
        template.for_each_recipient_tab(recipients) do |field|
          yielded_fields << field
        end

        expect(yielded_fields).to eq(
          tabs.values.flatten + fields.values.flatten
        )
      end
    end

    describe "as_composite_template_entry" do
      let(:sequence) { 1 }
      let(:document_entry) do
        { document: "entry" }
      end

      before do
        template.documents.each do |document|
          allow(document).to receive(:as_composite_template_entry).and_return(document_entry)
        end
      end

      it "combines all data into a single composite template entry" do
        template.documents.each do |document|
          expect(document)
            .to receive(:as_composite_template_entry)
            .with(template.recipients.values.flatten)
        end

        expect(template.as_composite_template_entry(template.recipients, sequence)).to eq(
          sequence: sequence.to_s,
          recipients: {}.tap do |result|
            template.recipients.each do |type, type_recipients|
              result[type] = type_recipients.map(&:as_composite_template_entry)
            end
          end,
          documents: template.documents.map(&:as_composite_template_entry)
        )
      end
    end

    describe "async_as_composite_template_entry" do
      let(:sequence) { 1 }
      let(:sync_result) do
        { some: "result" }
      end

      before do
        allow(template).to receive(:as_composite_template_entry).and_return(sync_result)
      end

      it "returns the same data as as_composite_template_entry" do
        expect(
          template.async_as_composite_template_entry(template.recipients, sequence)
        ).to eq(
          template.as_composite_template_entry(template.recipients, sequence)
        )
      end
    end
  end
end

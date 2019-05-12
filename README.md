# DocusignTemplates

This Ruby library is useful for:

- Parsing DocuSign Templates into YML
- Writing data for static tabs directly into the PDF with high performance
- Creating composite template API call entries from multiple templates

DocuSign's API performance degrades *rapidly* with the number of tabs in the envelope. In addition, the composite template API does not allow deleting unwanted tabs/signatures from templates.

 This library solves both issues by:

- If all text, checkbox, and radio group fields are static, the library allows mapping the data locally and printing it directly onto the PDF. This static PDF can then be uploaded to DocuSign in the composite templates call
- All other tabs can be marked as disabled. If disabled, the tab won't be included on the composite call.

In other words, it replaces `serverTemplates` in the composite call with `inlineTemplates` that have data printed to the PDF, and only a smaller set of required tabs included. Since all text, checkbox, and radio group tabs have been eliminated, the API sees a massive performance gain. Nifty!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'docusign_templates'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install docusign_templates

## Usage

First, download a template as JSON from DocuSign. Then, convert it to a new template as so:

```ruby
converter = DocusignTemplates::Converter.new("tmp/RIA.json")
template = converter.convert!("tmp", "ria")
```

If the template has already been converted, load it like so:

```ruby
template = DocusignTemplates::Template.new("tmp", "ria")
```

Then, select which roles you want to include by role name:

```ruby
recipient_roles = template.recipients_for_roles(["client", "secondary"])
```

Then, handle each field or tab:

```ruby
template.for_each_recipient_tab(recipient_roles) do |field|
  if field.is_pdf_field?
    field.value = get_field_value(field)
  else
    field.disabled = should_include_field?(field)
  end
end

# can also set document and recipient properties...
template.documents[0].merge!(name: "My Document.pdf")
recipient_roles.each do { |recipient| set_name_email(recipient) }
```

Once all fields/tabs are processed, create the composite template entry:

```ruby
processed_templates = required_templates.map do |template|
  recipients = get_required_template_recipients(template)
  process_template_for_recipients(recipients)
  [template, recipients]
end

composite_templates = processed_templates.map.with_index do |processed_template, sequence|
  template, recipients_for_template = processed_template

  {
    inline_templates: [
      template.as_composite_template_entry(
        recipients_for_template, sequence
      )
    ]
  }
end

composite_request = base_composite_request.merge(
  composite_templates: composite_templates
)

envelope_id = create_docusign_envelope(composite_request)
```

Repeat for each template needed for the envelope.

NOTE: Use `DocusignTemplates::Converter.camelize` and `DocusignTemplates::Converter.underscoreize` to switch between Ruby-friendly snake_case and the camelCase expected by DocuSign's API.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/JonathanPierce/docusign_templates.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

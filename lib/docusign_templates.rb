require "active_support/all"
require "base64"
require "json"
require "origami"
require "yaml"

require "docusign_templates/version"
require "docusign_templates/converter"
require "docusign_templates/template"
require "docusign_templates/document"
require "docusign_templates/recipient"
require "docusign_templates/field"
require "docusign_templates/pdf_writer"

module DocusignTemplates
  class Error < StandardError; end
end

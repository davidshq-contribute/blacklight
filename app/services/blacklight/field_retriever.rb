# frozen_string_literal: true

module Blacklight
  class FieldRetriever
    # @param [Blacklight::Document] document
    # @param [Blacklight::Configuration::Field] field_config solr field configuration
    # @param [ActionView::Base] view_context Rails rendering context
    def initialize(document, field_config, view_context = nil)
      @document = document
      @field_config = field_config
      @view_context = view_context
    end

    # @return [Blacklight::Document]
    attr_reader :document
    # @return [Blacklight::Configuration::Field]
    attr_reader :field_config
    # @return [ActionView::Base]
    attr_reader :view_context

    delegate :field, to: :field_config

    # @return [Array]
    def fetch
      if field_config.highlight
        value = retrieve_highlight
      end
      if value.blank?
        value = if field_config.accessor
                  retieve_using_accessor
                elsif field_config.values
                  retrieve_values
                else
                  retrieve_simple
                end
      end
      Array.wrap(value)
    end

    private

    def retrieve_simple
      # regular document field
      if field_config.default.is_a?(Proc)
        document.fetch(field_config.field, &field_config.default)
      else
        document.fetch(field_config.field, field_config.default)
      end
    end

    def retieve_using_accessor
      # implicit method call
      if field_config.accessor == true
        document.send(field)
      # arity-1 method call (include the field name in the call)
      elsif !field_config.accessor.is_a?(Array) && document.method(field_config.accessor).arity.nonzero?
        document.send(field_config.accessor, field)
      # chained method calls
      else
        Array(field_config.accessor).inject(document) do |result, method|
          result.send(method)
        end
      end
    end

    def retrieve_highlight
      # retrieve the document value from the highlighting response
      document.highlight_field(field_config.field).map(&:html_safe) if document.has_highlight_field? field_config.field
    end

    def retrieve_values
      field_config.values.call(field_config, document, view_context)
    end
  end
end

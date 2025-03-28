# frozen_string_literal: true

module Blacklight::ConfigurationHelperBehavior
  ##
  # Return the available sort fields
  # @return [Array<Blacklight::Configuration::Field>]
  def active_sort_fields
    blacklight_config.sort_fields.select { |_sort_key, field_config| should_render_field?(field_config) }
  end

  ##
  # Is the search form using the default search field ("all_fields" by default)?
  # @param [String] selected_search_field the currently selected search_field
  # @return [Boolean]
  def default_search_field?(selected_search_field)
    selected_search_field.blank? || (blacklight_config.default_search_field && selected_search_field == blacklight_config.default_search_field[:key])
  end

  ##
  # Look up the label for the facet field
  # @return [String]
  def facet_field_label field
    field_config = blacklight_config.facet_fields[field]
    field_config ||= Blacklight::Configuration::NullField.new(key: field)

    field_config.display_label('facet')
  end

  # Shortcut for commonly needed operation, look up display
  # label for the key specified.
  # @return [String]
  def label_for_search_field(key)
    field_config = blacklight_config.search_fields[key]
    return if key.nil? && field_config.nil?

    field_config ||= Blacklight::Configuration::NullField.new(key: key)

    field_config.display_label('search')
  end

  # @return [String]
  def sort_field_label(key)
    field_config = blacklight_config.sort_fields[key]
    field_config ||= Blacklight::Configuration::NullField.new(key: key)

    field_config.display_label('sort')
  end

  ##
  # Look up the label for a solr field.
  #
  # @overload label
  #   @param [Symbol] an i18n key
  #
  # @overload label, i18n_key, another_i18n_key, and_another_i18n_key
  #   @param [String] default label to display if the i18n look up fails
  #   @param [Symbol] i18n keys to attempt to look up
  #     before falling  back to the label
  #   @param [Symbol] any number of additional keys
  #   @param [Symbol] ...
  # @return [String]
  def field_label *i18n_keys
    first, *rest = i18n_keys.compact

    t(first, default: rest)
  end

  # @return [Hash<Symbol => Blacklight::Configuration::ViewConfig>]
  def document_index_views
    blacklight_config.view.select do |_k, config|
      should_render_field? config
    end
  end

  # filter #document_index_views to just views that should display in the view type control
  def document_index_view_controls
    document_index_views.select do |_k, config|
      config.display_control.nil? || blacklight_configuration_context.evaluate_configuration_conditional(config.display_control)
    end
  end

  ##
  # Get the default index view type
  def default_document_index_view_type
    document_index_views.select { |_k, config| config.respond_to?(:default) && config.default }.keys.first || document_index_views.keys.first
  end

  ##
  # Default sort field
  def default_sort_field
    (active_sort_fields.find { |_k, config| config.respond_to?(:default) && config.default } || active_sort_fields.first)&.last
  end

  ##
  # Determine whether to render a field by evaluating :if and :unless conditions
  #
  # @param [Blacklight::Solr::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_field?(field_config, *)
    blacklight_configuration_context.evaluate_if_unless_configuration(field_config, *)
  end
end

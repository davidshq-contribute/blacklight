# frozen_string_literal: true

class Blacklight::Solr::InvalidParameter < ArgumentError; end

class Blacklight::Solr::Request < ActiveSupport::HashWithIndifferentAccess
  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super
    end
  end

  def append_query(query)
    return if query.nil?

    if self['q'] || dig(:json, :query, :bool)
      self[:json] ||= { query: { bool: { must: [] } } }
      self[:json][:query] ||= { bool: { must: [] } }
      self[:json][:query][:bool][:must] << query

      if self['q']
        self[:json][:query][:bool][:must] << self['q']
        delete 'q'
      end
    else
      self['q'] = query
    end
  end

  def append_boolean_query(bool_operator, query)
    return if query.blank?

    self[:json] ||= { query: { bool: { bool_operator => [] } } }
    self[:json][:query] ||= { bool: { bool_operator => [] } }
    self[:json][:query][:bool][bool_operator] ||= []

    if self['q'].present?
      self[:json][:query][:bool][:must] ||= []
      self[:json][:query][:bool][:must] << self['q']
      delete 'q'
    end

    self[:json][:query][:bool][bool_operator] << query
  end

  def append_filter_query(query)
    self['fq'] ||= []
    self['fq'] = Array(self['fq']) if self['fq'].is_a? String

    self['fq'] << query
  end

  def append_facet_fields(values)
    self['facet.field'] ||= []
    self['facet.field'] += Array(values)
  end

  def append_facet_query(values)
    self['facet.query'] ||= []
    self['facet.query'] += Array(values)
  end

  def append_facet_pivot(query)
    self['facet.pivot'] ||= []
    self['facet.pivot'] << query
  end

  def append_highlight_field(query)
    self['hl.fl'] ||= []
    self['hl.fl'] << query
  end
end

# frozen_string_literal: true

RSpec.describe Blacklight::ConfigurationHelperBehavior do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:config_value) { double }

  before do
    allow(helper).to receive_messages(blacklight_config: blacklight_config)
  end

  describe "#active_sort_fields" do
    it "restricts the configured sort fields to only those that should be displayed" do
      allow(blacklight_config).to receive_messages(sort_fields: { a: double(if: false, unless: false), b: double(if: true, unless: true) })
      expect(helper.active_sort_fields).to be_empty
    end
  end

  describe "#default_document_index_view_type" do
    it "uses the first view with default set to true" do
      blacklight_config.view.a
      blacklight_config.view.b(default: true)
      expect(helper.default_document_index_view_type).to eq :b
    end

    it "defaults to the first configured index view" do
      allow(blacklight_config).to receive_messages(view: { a: true, b: true })
      expect(helper.default_document_index_view_type).to eq :a
    end
  end

  describe "#document_index_views" do
    before do
      blacklight_config.view.abc = false
      blacklight_config.view.def(if: false)
      blacklight_config.view.xyz(unless: true)
    end

    it "filters views using :if/:unless configuration" do
      expect(helper.document_index_views).to have_key :list
      expect(helper.document_index_views).not_to have_key :abc
      expect(helper.document_index_views).not_to have_key :def
      expect(helper.document_index_views).not_to have_key :xyz
    end
  end

  describe '#document_index_view_controls' do
    before do
      blacklight_config.view.a({})
      blacklight_config.view.b(display_control: false)
    end

    it "filters index views to those set to display controls" do
      expect(helper.document_index_view_controls).to have_key :a
      expect(helper.document_index_view_controls).not_to have_key :b
    end
  end

  describe "#field_label" do
    it "looks up the label as an i18n string" do
      expect(helper).to receive(:t).with(:some_key, default: []).and_return "my label"
      label = helper.field_label :some_key

      expect(label).to eq "my label"
    end

    it "passes the provided i18n keys to I18n.t" do
      expect(helper).to receive(:t).with(:key_a, default: [:key_b, "default text"])

      helper.field_label :key_a, :key_b, "default text"
    end

    it "compacts nil keys (fixes rails/rails#19419)" do
      expect(helper).to receive(:t).with(:key_a, default: [:key_b])

      helper.field_label :key_a, nil, :key_b
    end
  end

  describe "#default_sort_field" do
    it "is the configured default field" do
      allow(helper).to receive_messages(blacklight_config: double(sort_fields: { a: double(default: nil), b: double(key: 'b', default: true) }))
      expect(helper.default_sort_field.key).to eq 'b'
    end

    it "is the first active sort field value if a default isn't set" do
      allow(helper).to receive_messages(blacklight_config: double(sort_fields: { a: double(key: 'a', default: nil), b: double(key: 'b', default: nil) }))
      expect(helper.default_sort_field.key).to eq 'a'
    end

    it "is the first active sort field value if the configured default field is not active" do
      allow(helper).to receive_messages(blacklight_config: double(sort_fields: { a: double(default: nil, key: 'a'), b: double(key: 'b', default: true, if: false) }))
      expect(helper.default_sort_field.key).to eq 'a'
    end
  end

  describe "#should_render_field?" do
    let(:field_config) { double('field config', if: true, unless: false) }

    it "is true" do
      expect(helper.should_render_field?(field_config)).to be true
    end

    it "is false if the :if condition is false" do
      allow(field_config).to receive_messages(if: false)
      expect(helper.should_render_field?(field_config)).to be false
    end

    it "is false if the :unless condition is true" do
      allow(field_config).to receive_messages(unless: true)
      expect(helper.should_render_field?(field_config)).to be false
    end
  end

  context 'labels' do
    let(:field_config) { { 'my-key' => double('field', display_label: 'My Field') } }

    before do
      allow(helper).to receive_messages(blacklight_config: config)
    end

    describe '#label_for_search_field' do
      let(:config) { double('Blacklight configuration', search_fields: field_config) }

      it 'handles a found key' do
        expect(helper.label_for_search_field('my-key')).to eq 'My Field'
      end

      it 'handles a missing key' do
        expect(helper.label_for_search_field('not-found')).to eq 'Not Found'
      end

      it 'handles a missing field' do
        expect(helper.label_for_search_field(nil)).to be_nil
      end
    end

    describe '#sort_field_label' do
      let(:config) { double('Blacklight configuration', sort_fields: field_config) }

      it 'handles a found key' do
        expect(helper.sort_field_label('my-key')).to eq 'My Field'
      end

      it 'handles a missing key' do
        expect(helper.sort_field_label('not-found')).to eq 'Not Found'
      end
    end
  end
end

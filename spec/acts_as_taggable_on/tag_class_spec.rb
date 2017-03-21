# -*- encoding : utf-8 -*-

require 'spec_helper'

describe ActsAsTaggableOn::TagClass do
  let(:base_class) { ActsAsTaggableOn::Tag }

  class ActsAsTaggableOn::Tag::TestTag
  end

  describe '#class' do
    it 'should create subclass no not exists' do
      subject = described_class.new("Product", base_class).class
      expect(subject.name).to eq 'ActsAsTaggableOn::Tag::ProductTag'
      expect(subject.superclass).to eq base_class
    end

    it 'should use existing subclass' do
      subject = described_class.new("Test", base_class).class
      expect(subject).to eq ActsAsTaggableOn::Tag::TestTag
    end
  end
end

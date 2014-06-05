# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ActsAsTaggableOn::TagListParser do
  it '#parse should return empty array if empty array is passed' do
    expect(ActsAsTaggableOn::TagListParser.parse([])).to be_empty
  end

  describe 'Multiple Delimiter' do
    before do
      @old_delimiter = ActsAsTaggableOn.delimiter
    end

    after do
      ActsAsTaggableOn.delimiter = @old_delimiter
    end

    it 'should separate tags by delimiters' do
      ActsAsTaggableOn.delimiter = [',', ' ', '\|']
      tag_list = ActsAsTaggableOn::TagListParser.parse('cool, data|I have')
      expect(tag_list.to_s).to eq('cool, data, I, have')
    end

    it 'should escape quote' do
      ActsAsTaggableOn.delimiter = [',', ' ', '\|']
      tag_list = ActsAsTaggableOn::TagListParser.parse "'I have'|cool, data"
      expect(tag_list.to_s).to eq('"I have", cool, data')

      tag_list = ActsAsTaggableOn::TagListParser.parse '"I, have"|cool, data'
      expect(tag_list.to_s).to eq('"I, have", cool, data')
    end

    it 'should work for utf8 delimiter and long delimiter' do
      ActsAsTaggableOn.delimiter = ['，', '的', '可能是']
      tag_list = ActsAsTaggableOn::TagListParser.parse('我的东西可能是不见了，还好有备份')
      expect(tag_list.to_s).to eq('我， 东西， 不见了， 还好有备份')
    end

    it 'should work for multiple quoted tags' do
      ActsAsTaggableOn.delimiter = [',']
      tag_list = ActsAsTaggableOn::TagListParser.parse('"Ruby Monsters","eat Katzenzungen"')
      expect(tag_list.to_s).to eq('Ruby Monsters, eat Katzenzungen')
    end
  end

end

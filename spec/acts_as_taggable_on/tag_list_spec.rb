# encoding: utf-8
require 'spec_helper'

describe ActsAsTaggableOn::TagList do
  let(:tag_list) { ActsAsTaggableOn::TagList.new('awesome', 'radical') }

  it { should be_kind_of Array }

  it '#from should return empty array if empty array is passed' do
    expect(ActsAsTaggableOn::TagList.from([])).to be_empty
  end

  describe '#add' do
    it 'should be able to be add a new tag word' do
      tag_list.add('cool')
      expect(tag_list.include?('cool')).to be_true
    end

    it 'should be able to add delimited lists of words' do
      tag_list.add('cool, wicked', :parse => true)
      expect(tag_list).to include('cool', 'wicked')
    end

    it 'should be able to add delimited list of words with quoted delimiters' do
      tag_list.add("'cool, wicked', \"really cool, really wicked\"", :parse => true)
      expect(tag_list).to include('cool, wicked', 'really cool, really wicked')
    end

    it 'should be able to handle other uses of quotation marks correctly' do
      tag_list.add("john's cool car, mary's wicked toy", :parse => true)
      expect(tag_list).to include("john's cool car", "mary's wicked toy")
    end

    it 'should be able to add an array of words' do
      tag_list.add(%w(cool wicked), :parse => true)
      expect(tag_list).to include('cool', 'wicked')
    end

    it 'should quote escape tags with commas in them' do
      tag_list.add('cool', 'rad,bodacious')
      expect(tag_list.to_s).to eq("awesome, radical, cool, \"rad,bodacious\"")
    end

  end

  describe '#remove' do
    it 'should be able to remove words' do
      tag_list.remove('awesome')
      expect(tag_list).to_not include('awesome')
    end

    it 'should be able to remove delimited lists of words' do
      tag_list.remove('awesome, radical', :parse => true)
      expect(tag_list).to be_empty
    end

    it 'should be able to remove an array of words' do
      tag_list.remove(%w(awesome radical), :parse => true)
      expect(tag_list).to be_empty
    end
  end

  describe '#to_s' do
    it 'should give a delimited list of words when converted to string' do
      expect(tag_list.to_s).to eq('awesome, radical')
    end

    it 'should be able to call to_s on a frozen tag list' do
      tag_list.freeze
      expect(lambda { tag_list.add('cool', 'rad,bodacious') }).to raise_error
      expect(lambda { tag_list.to_s }).to_not raise_error
    end
  end

  describe 'cleaning' do
    it 'should parameterize if force_parameterize is set to true' do
      ActsAsTaggableOn.force_parameterize = true
      tag_list = ActsAsTaggableOn::TagList.new('awesome()', 'radical)(cc')

      expect(tag_list.to_s).to eq('awesome, radical-cc')
      ActsAsTaggableOn.force_parameterize = false
    end

    it 'should lowercase if force_lowercase is set to true' do
      ActsAsTaggableOn.force_lowercase = true

      tag_list = ActsAsTaggableOn::TagList.new('aweSomE', 'RaDicaL', 'Entrée')
      expect(tag_list.to_s).to eq('awesome, radical, entrée')

      ActsAsTaggableOn.force_lowercase = false
    end

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
      tag_list = ActsAsTaggableOn::TagList.from 'cool, data|I have'
      expect(tag_list.to_s).to eq('cool, data, I, have')
    end

    it 'should escape quote' do
      ActsAsTaggableOn.delimiter = [',', ' ', '\|']
      tag_list = ActsAsTaggableOn::TagList.from "'I have'|cool, data"
      expect(tag_list.to_s).to eq('"I have", cool, data')

      tag_list = ActsAsTaggableOn::TagList.from '"I, have"|cool, data'
      expect(tag_list.to_s).to eq('"I, have", cool, data')
    end

    it 'should work for utf8 delimiter and long delimiter' do
      ActsAsTaggableOn.delimiter = ['，', '的', '可能是']
      tag_list = ActsAsTaggableOn::TagList.from '我的东西可能是不见了，还好有备份'
      expect(tag_list.to_s).to eq('我， 东西， 不见了， 还好有备份')
    end

    it 'should work for multiple quoted tags' do
      ActsAsTaggableOn.delimiter = [',']
      tag_list = ActsAsTaggableOn::TagList.from '"Ruby Monsters","eat Katzenzungen"'
      expect(tag_list.to_s).to eq('Ruby Monsters, eat Katzenzungen')
    end
  end

end

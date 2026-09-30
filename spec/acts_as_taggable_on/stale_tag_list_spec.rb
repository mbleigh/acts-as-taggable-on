# frozen_string_literal: true

require 'spec_helper'

# A tag list that was only read must not be written back on an unrelated save.
# See issues #576, #975, #233.
RSpec.describe 'Stale tag lists' do
  def tagging_names(record, context = 'tags')
    ActsAsTaggableOn::Tagging.where(taggable: record, context: context).includes(:tag).map { |t| t.tag.name }.sort
  end

  describe 'on a model with a cached column' do
    let!(:record) { CachedModel.create!(name: 'original') }

    it 'preserves tags added by another instance after a stale read and an unrelated save' do
      a = CachedModel.find(record.id)
      expect(a.tag_list).to be_empty

      b = CachedModel.find(record.id)
      b.tag_list = ['runner']
      b.save!

      a.update!(name: 'x')

      expect(tagging_names(record)).to eq(['runner'])
      expect(CachedModel.find(record.id).cached_tag_list).to eq('runner')
    end

    it 'does not resurrect tags removed by another instance' do
      record.update!(tag_list: %w[runner walker])
      a = CachedModel.find(record.id)
      expect(a.tag_list.sort).to eq(%w[runner walker])

      b = CachedModel.find(record.id)
      b.tag_list.remove('walker')
      b.save!

      a.update!(name: 'x')

      expect(tagging_names(record)).to eq(['runner'])
      expect(CachedModel.find(record.id).cached_tag_list).to eq('runner')
    end

    it 'does not clobber a concurrent add after this instance saved its own change' do
      a = CachedModel.find(record.id)
      a.tag_list.add('mine')
      a.save!

      b = CachedModel.find(record.id)
      b.tag_list.add('theirs')
      b.save!

      a.update!(name: 'x')

      expect(tagging_names(record)).to eq(%w[mine theirs])
      expect(CachedModel.find(record.id).cached_tag_list.split(', ').sort).to eq(%w[mine theirs])
    end

    it 'handles a nil cached column' do
      CachedModel.where(id: record.id).update_all(cached_tag_list: nil)
      other = CachedModel.find(record.id)
      a = CachedModel.find(record.id)
      expect(a.tag_list).to be_empty

      other.update!(tag_list: ['runner'])
      a.update!(name: 'x')

      expect(tagging_names(record)).to eq(['runner'])
    end

    it 'handles an empty cached column' do
      CachedModel.where(id: record.id).update_all(cached_tag_list: '')
      other = CachedModel.find(record.id)
      a = CachedModel.find(record.id)
      expect(a.tag_list).to be_empty

      other.update!(tag_list: ['runner'])
      a.update!(name: 'x')

      expect(tagging_names(record)).to eq(['runner'])
      expect(CachedModel.find(record.id).cached_tag_list).to eq('runner')
    end
  end

  describe 'persisting real changes' do
    let!(:record) { TaggableModel.create!(name: 'original') }

    it 'persists assignment' do
      record.tag_list = 'a, b'
      record.save!
      expect(tagging_names(record)).to eq(%w[a b])
    end

    it 'persists in-place add/remove across successive saves' do
      record.tag_list.add('a')
      record.save!
      expect(tagging_names(record)).to eq(['a'])

      record.tag_list.add('b')
      record.save!
      expect(tagging_names(record)).to eq(%w[a b])

      record.tag_list.remove('a')
      record.save!
      expect(tagging_names(record)).to eq(['b'])
    end

    it 'persists set_tag_list_on without a prior read' do
      fresh = TaggableModel.find(record.id)
      fresh.set_tag_list_on(:tags, 'x, y')
      fresh.save!
      expect(tagging_names(record)).to eq(%w[x y])
    end

    it 'persists set_tag_list_on for a custom context without a prior read' do
      fresh = TaggableModel.find(record.id)
      fresh.set_tag_list_on(:customs, 'z')
      fresh.save!
      expect(tagging_names(record, 'customs')).to eq(['z'])
    end

    it 'does not rewrite another context when only one changes (#576)' do
      record.update!(skill_list: 'ruby', language_list: 'english')
      a = TaggableModel.find(record.id)
      a.language_list # stale read

      b = TaggableModel.find(record.id)
      b.language_list.add('french')
      b.save!

      a.skill_list.add('rails')
      a.save!

      expect(tagging_names(record, 'skills')).to eq(%w[rails ruby])
      expect(tagging_names(record, 'languages')).to eq(%w[english french])
    end

    it 'persists after a validation failure and retry' do
      record.tag_list.add('a')
      record.name = 'x'
      allow(record).to receive(:valid?).and_return(false)
      expect(record.save).to be(false)
      allow(record).to receive(:valid?).and_call_original
      record.save!
      expect(tagging_names(record)).to eq(['a'])
    end

    it 'persists after a transaction rollback and retry' do
      record.tag_list.add('a')
      TaggableModel.transaction(requires_new: true) do
        record.save!
        raise ActiveRecord::Rollback
      end
      expect(tagging_names(record)).to eq([])

      record.save!
      expect(tagging_names(record)).to eq(['a'])
    end

    it 'resets state on reload' do
      a = TaggableModel.find(record.id)
      a.tag_list.add('local')
      a.reload
      a.tag_list # re-read after reload

      TaggableModel.find(record.id).update!(tag_list: ['remote'])
      a.update!(name: 'x')

      expect(tagging_names(record)).to eq(['remote'])
    end
  end

  describe 'with preserve_tag_order' do
    let!(:record) { OrderedTaggableModel.create!(name: 'o', tag_list: 'a, b, c') }

    it 'persists a reorder' do
      r = OrderedTaggableModel.find(record.id)
      r.tag_list = 'c, b, a'
      r.save!
      expect(OrderedTaggableModel.find(record.id).tag_list).to eq(%w[c b a])
    end

    it 'does not rewrite on an unrelated save after a read' do
      a = OrderedTaggableModel.find(record.id)
      a.tag_list
      OrderedTaggableModel.find(record.id).update!(tag_list: 'a, b, c, d')
      a.update!(name: 'x')
      expect(OrderedTaggableModel.find(record.id).tag_list).to eq(%w[a b c d])
    end
  end
end

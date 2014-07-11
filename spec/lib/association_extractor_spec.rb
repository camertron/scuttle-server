# encoding: UTF-8

require 'spec_helper'
require 'lib/association_extractor'

describe AssociationExtractor do
  def extract(ruby_code)
    AssociationExtractor.extract_associations(ruby_code)
  end

  def verify(hash, first, second, type, association_name = nil, foreign_key = nil)
    expect(hash[:first]).to eq(first)
    expect(hash[:second]).to eq(second)
    expect(hash[:type]).to eq(type)
    expect(hash[:association_name]).to eq(association_name)
    expect(hash[:foreign_key]).to eq(foreign_key)
  end

  describe '#extract_associations' do
    context 'with a set of simple ar models' do
      let(:models) do
        %Q{
          class Post < ActiveRecord::Base
            has_many :comments
          end

          class Comment < ActiveRecord::Base
            belongs_to :post
          end
        }
      end

      it 'should identify the associations' do
        extract(models).tap do |result|
          expect(result.size).to eq(2)
          verify(result.first, 'posts', 'comments', :has_many, 'comments')
          verify(result.last, 'comments', 'posts', :belongs_to, 'post')
        end
      end
    end

    context 'with an ar model that contains a class_name override' do
      let(:models) do
        %Q{
          class Post < ActiveRecord::Base
            has_many :chats, class_name: 'Comment'
          end

          class Comment < ActiveRecord::Base
            belongs_to :post
          end
        }
      end

      it 'should identify the associations' do
        extract(models).tap do |result|
          expect(result.size).to eq(2)
          verify(result.first, 'posts', 'comments', :has_many, 'chats')
          verify(result.last, 'comments', 'posts', :belongs_to, 'post')
        end
      end
    end

    context 'with an ar model that contains a foreign key override' do
      let(:models) do
        %Q{
          class Post < ActiveRecord::Base
            has_many :comments, association_foreign_key: 'MyCommentId'
          end

          class Comment < ActiveRecord::Base
            belongs_to :post
          end
        }
      end

      it 'should identify the associations' do
        extract(models).tap do |result|
          expect(result.size).to eq(2)
          verify(result.first, 'posts', 'comments', :has_many, 'comments', 'MyCommentId')
          verify(result.last, 'comments', 'posts', :belongs_to, 'post')
        end
      end
    end
  end
end

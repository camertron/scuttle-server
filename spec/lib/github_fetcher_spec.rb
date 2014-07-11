# encoding: UTF-8

require 'spec_helper'
require 'lib/github_fetcher'
require 'zip'

shared_context :test_file_contents do
  let(:model_file_contents) do
    %Q{
      class Post < ActiveRecord::Base
        has_many :comments
      end

      class Comment < ActiveRecord::Base
        belongs_to :post
      end
    }
  end

  let(:controller_file_contents) do
    %Q{
      class ApplicationController < ActionController::Base
        protect_from_forgery
      end
    }
  end
end

describe GithubFetcher do
  include_context :test_file_contents

  let(:client) { TestClient.new }
  let(:downloader) { TestDownloader.new }
  let(:fetcher) { GithubFetcher.new(client, downloader) }

  describe '#fetch_zip_archive' do
    before(:each) do
      downloader.add_file('my_project/app/models/post.rb', model_file_contents)
      downloader.add_file('my_project/app/controllers/application_controller.rb', controller_file_contents)
    end

    it 'should grab the archive from the internet (stubbed out by TestDownloader)' do
      fetcher.fetch_zip_archive('user/repo').tap do |archive|
        Zip::File.open_buffer(archive.archive_file) do |zip_file|
          zip_file.map(&:name).should == [
            'my_project/app/models/post.rb',
            'my_project/app/controllers/application_controller.rb'
          ]
        end
      end
    end
  end
end

describe GithubArchive do
  include_context :test_file_contents

  let(:downloader) { TestDownloader.new }
  let(:archive) { GithubArchive.new(downloader.download_file) }

  before(:each) do
    downloader.add_file('my_project/app/models/post.rb', model_file_contents)
    downloader.add_file('my_project/app/controllers/application_controller.rb', controller_file_contents)
  end

  describe '#each_file_contents' do
    it 'yields the contents of all the files in the blob' do
      archive.each_file_contents('*/app/models/**/**.rb').to_a.tap do |contents_arr|
        expect(contents_arr.size).to eq(1)
        expect(contents_arr.first).to eq(model_file_contents)
      end

      archive.each_file_contents('*/app/controllers/**/**.rb').to_a.tap do |contents_arr|
        expect(contents_arr.size).to eq(1)
        expect(contents_arr.first).to eq(controller_file_contents)
      end
    end
  end
end

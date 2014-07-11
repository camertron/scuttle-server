# encoding: UTF-8

require 'spec_helper'

describe "github_import.json" do
  def make_request(repo)
    params = { repo: repo }
    get "/github_import.json?#{params_to_s(params)}"
  end

  let(:post_contents) do
    %Q{
      class Post < ActiveRecord::Base
        has_many :comments
      end
    }
  end

  let(:comment_contents) do
    %Q{
      class Comment < ActiveRecord::Base
        belongs_to :post
      end
    }
  end

  before(:each) do
    # Prime the pump by tricking rack into instantiating our app.
    # Yes. This is kind of a hack.
    get '/'

    # clear commits from previous tests
    app.instance.github_user.api.commits.clear
  end

  context "with some files in an archive" do
    before(:each) do
      # now that downloader is available, add the appropriate files
      app.instance.downloader.tap do |downloader|
        downloader.reset
        downloader.add_file('my_project/app/models/post.rb', post_contents)
        downloader.add_file('my_project/app/models/comment.rb', comment_contents)
      end
    end

    it "extracts associations correctly" do
      make_request('camertron/scuttle-server')
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        "result" => "succeeded", "associations" => [
          { "first" => "posts", "second" => "comments", "type" => "has_many", "association_name" => "comments" },
          { "first" => "comments", "second" => "posts", "type" => "belongs_to", "association_name" => "post" }
        ]
      })
    end

    it "should fetch previously extracted associations from the database instead of extracting a second time" do
      app.instance.github_user.api.commits["camertron/scuttle-server|master"] = { sha: "abc123" }

      AssociationCache.create(
        owner: "camertron", repo: "scuttle-server",
        sha1: "abc123", association_json: '[{"foo":"bar"}]'
      )

      mock(AssociationExtractor).extract_associations.never
      make_request('camertron/scuttle-server')
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        "result" => "succeeded", "associations" => [{ "foo" => "bar" }]
      })
    end
  end

  it "returns an error message if the repository can't be found on github" do
    app.instance.github_user.api.commits["camertron/scuttle-server|master"] = nil
    make_request('camertron/scuttle-server')
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({
      "result" => "failed", "associations" => [], "message" => "Repo not found."
    })
  end

  it "returns an error message if an unexpected error is caught" do
    stub(RepoName).parse { raise "Jelly beans" }
    make_request('camertron/scuttle-server')
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({
      "result" => "failed", "associations" => [], "message" => "Jelly beans"
    })
  end
end

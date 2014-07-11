# encoding: UTF-8

require 'spec_helper'

describe "convert.json" do
  def make_request(sql, associations = [])
    params = { sql: sql, associations: associations.to_json }
    get "/convert.json?#{params_to_s(params)}"
  end

  def format(str)
    Scuttle.colorize(Scuttle.beautify(str), :div)
  end

  it "returns an arel response on success" do
    make_request('SELECT * FROM posts LIMIT 1')
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({
      "result" => "succeeded", "arel" => format("Post.select(Arel.star).limit(1)")
    })
  end

  it "returns an arel response respecting basic associations" do
    associations = [
      { first: 'posts', second: 'comments', type: 'has_many' },
      { first: 'comments', second: 'posts', type: 'belongs_to' }
    ]

    make_request('SELECT * FROM posts INNER JOIN comments ON posts.id = comments.post_id', associations)
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({
      "result" => "succeeded", "arel" => format("Post.select(Arel.star).joins(:comments)")
    })
  end

  it "returns an arel response respecting an association with a custom foreign key" do
    associations = [
      { first: 'posts', second: 'comments', type: 'has_many', foreign_key: 'my_post_id' },
      { first: 'comments', second: 'posts', type: 'belongs_to', foreign_key: 'my_post_id' }
    ]

    make_request('SELECT * FROM posts INNER JOIN comments ON posts.id = comments.my_post_id', associations)
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({
      "result" => "succeeded", "arel" => format("Post.select(Arel.star).joins(:comments)")
    })
  end

  it "returns an arel response respecting an association with a custom association name" do
    associations = [
      { first: 'posts', second: 'comments', type: 'has_many', association_name: 'foobar' },
      { first: 'comments', second: 'posts', type: 'belongs_to' }
    ]

    make_request('SELECT * FROM posts INNER JOIN comments ON posts.id = comments.post_id', associations)
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({
      "result" => "succeeded", "arel" => format("Post.select(Arel.star).joins(:foobar)")
    })
  end

  it "returns an error if one occurs" do
    stub(Scuttle).colorize { raise Scuttle::ScuttleConversionError, "Jelly beans" }
    make_request("SELECT * FROM posts")
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({
      "result" => "failed", "message" => "Jelly beans", "arel" => nil
    })
  end
end

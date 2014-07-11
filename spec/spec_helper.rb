# encoding: UTF-8

$:.push(File.join(File.dirname(__FILE__), '..'))

require 'rspec'
require 'rack/test'
require 'cgi'
require 'pathname'
require 'pry-nav'

require 'app'

RSpec.configure do |config|
  config.include(Rack::Test::Methods)
  config.mock_with :rr

  def app
    ScuttleServer::TestApp
  end

  def params_to_s(params)
    param_str = params.map do |key, val|
      "#{key}=#{CGI.escape(val)}"
    end.join("&")
  end
end

module ScuttleServer
  class TestApp < ScuttleServer::App

    class << self
      attr_accessor :instance
    end

    def initialize
      # give tests access to the current app instance
      self.class.instance = self
      super
    end

    def downloader
      @downloader ||= TestDownloader.new
    end

    def github_user
      @github_user ||= Struct.new(:api).new(TestClient.new)
    end

  end
end

class TestClient
  HEX_CHARS = ('a'..'f').to_a + ('0'..'9').to_a

  attr_reader :commits

  def archive_link(repo, options)
    "http://google.com"
  end

  def commit(repo, branch)
    commits.fetch("#{repo}|#{branch}", {
      sha: 40.times.map { HEX_CHARS.sample }.join
    })
  end

  def commits
    @commits ||= {}
  end
end

class TestDownloader
  attr_reader :file, :zip_stream

  def initialize
    reset
  end

  def reset
    if zip_stream
      zip_stream.close
    end

    @file = Tempfile.new('test')
    @file.binmode
    @zip_stream = Zip::OutputStream.open(@file)
  end

  def add_file(name, contents)
    zip_stream.put_next_entry(name)
    zip_stream.print(contents)
  end

  def download_file(uri = nil)
    zip_stream.close
    file.rewind
    file
  end
end

Pathname(__FILE__).dirname.dirname.join("log").tap do |log_path|
  FileUtils.mkdir_p(log_path.to_s)
  ActiveRecord::Base.logger = Logger.new(log_path.join("test.log").to_s)
end

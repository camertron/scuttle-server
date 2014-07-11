# encoding: UTF-8

require 'zip'
require 'tempfile'
require 'uri'

class GithubFetcher
  attr_reader :client, :downloader

  def initialize(client, downloader)
    @client = client
    @downloader = downloader
  end

  def fetch_zip_archive(repo)
    archive_uri = URI.parse(client.archive_link(repo, format: 'zipball'))
    GithubArchive.new(downloader.download_file(archive_uri))
  end
end

class GithubArchive
  attr_reader :archive_file

  def initialize(archive_file)
    @archive_file = archive_file
  end

  def each_file_contents(glob)
    if block_given?
      Zip::File.open_buffer(archive_file) do |zip_file|
        zip_file.glob(glob).each do |entry|
          yield entry.get_input_stream.read
        end
      end
    else
      to_enum(__method__, glob)
    end
  end

  def cleanup
    archive_file.unlink
  end
end

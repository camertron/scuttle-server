# encoding: UTF-8

require 'net/http'

class FileDownloader
  class << self

    def download_file(uri)
      dest = Tempfile.new('archive')
      dest.binmode # switch to binary

      Net::HTTP.start(uri.host, use_ssl: uri.scheme == 'https') do |http|
        http.request_get(uri.path) do |resp|
          resp.read_body do |segment|
            dest.write(segment)
          end
        end
      end

      dest.rewind
      dest
    end

  end
end

# encoding: UTF-8

require 'sinatra'
require 'scuttle'
require 'json'

require 'sinatra_auth_github'
require 'sinatra/activerecord'

require 'lib/association_extractor'
require 'lib/file_downloader'
require 'lib/github_fetcher'
require 'lib/repo_name'

require 'models/association_cache'

module ScuttleServer
  class App < Sinatra::Base
    register Sinatra::ActiveRecordExtension

    enable :sessions

    set :github_options, {
      scopes:    'repo',
      secret:    ENV['GITHUB_CLIENT_SECRET'],
      client_id: ENV['GITHUB_CLIENT_ID'],
    }

    register Sinatra::Auth::Github

    get '/login' do
      authenticate!
      redirect to('/')
    end

    get '/logout' do
      logout!
      redirect to('/')
    end

    get '/' do
      erb :index
    end

    get '/github_import.json' do
      begin
        content_type :json

        repo_name = RepoName.parse(params[:repo])
        commit = github_user.api.commit(repo_name.to_s, 'master') rescue nil

        if commit
          record = AssociationCache.where(
            owner: repo_name.owner,
            repo: repo_name.repo,
            sha1: commit[:sha]
          ).first_or_initialize

          if record.new_record?
            archive = GithubFetcher.new(github_user.api, downloader).fetch_zip_archive(repo_name.to_s)

            record.association_json = archive.each_file_contents('*/app/models/**/**.rb').flat_map do |ruby_code|
              AssociationExtractor.extract_associations(ruby_code)
            end.to_json

            archive.cleanup
            record.save
          end

          { result: 'succeeded', associations: JSON.parse(record.association_json) }.to_json
        else
          { result: 'failed', associations: [], message: 'Repo not found.' }.to_json
        end
      rescue => e
        { result: 'failed', associations: [], message: e.message }.to_json
      end
    end

    post '/convert.json' do
      begin
        content_type :json

        options = {
          use_arel_helpers: params.fetch('use_arel_helpers', 'false') == 'true',
          use_arel_nodes_prefix: params.fetch('use_arel_nodes_prefix', 'true') == 'true'
        }

        puts options.inspect

        arel = Scuttle.colorize(
          Scuttle.beautify(
            Scuttle.convert(
              params.fetch('sql', ""), options,
              AssociationCache.create_manager(JSON.parse(params.fetch('associations', '[]')))
            )
          ), :div
        )

        { result: "succeeded", arel: arel }.to_json
      rescue Scuttle::ScuttleConversionError => e
        { result: "failed", arel: nil, message: e.message }.to_json
      end
    end

    private

    def downloader
      FileDownloader
    end
  end
end

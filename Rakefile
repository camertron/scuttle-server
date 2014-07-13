# encoding: UTF-8

require 'yaml'
require 'fileutils'
require 'pathname'

require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'

# List of environments and their heroku git remotes
ENVIRONMENTS = {
  :staging => 'scuttle-server-staging',
  :production => 'scuttle-server'
}

namespace :bower do
  task :install do
    system('bower install')

    YAML.load_file('./bower.yml').each_pair do |lib_name, files|
      lib_path = Pathname("./bower_components/#{lib_name}")
      public_path = Pathname('./public')

      files.each_pair do |source_file, dest_dir|
        source_regexp = Regexp.new(
          source_file.split(/({\w})/).map do |part|
            if part =~ /{(\w)}/
              case Regexp.last_match.captures.first
                when 'd' then '\\d'
              end
            else
              Regexp.escape(part)
            end
          end.join
        )

        lib_file = Pathname(
          Dir.glob(lib_path.join('**').join('**').to_s).find do |file|
            file =~ source_regexp
          end
        )

        public_file = public_path.join(dest_dir).join(lib_name).join(File.basename(lib_file))
        FileUtils.mkdir_p(public_file.dirname.to_s)

        puts "Copying #{lib_file} -> #{public_file}"
        FileUtils.cp(lib_file.expand_path.to_s, public_file.expand_path.to_s, force: true)
      end
    end
  end
end

namespace :deploy do
  ENVIRONMENTS.keys.each do |env|
    desc "Deploy to #{env}"
    task env do
      current_branch = `git branch | grep ^* | awk '{ print $2 }'`.strip
      Rake::Task['deploy:before_deploy'].invoke(env, current_branch)
      Rake::Task['deploy:update_code'].invoke(env, current_branch)
      Rake::Task['deploy:after_deploy'].invoke(env, current_branch)
    end
  end

  task :before_deploy, :env, :branch do |t, args|
    puts "Deploying #{args[:branch]} to #{args[:env]}"
  end

  task :after_deploy, :env, :branch do |t, args|
    puts "Bundling assets..."

    Bundler.with_clean_env do
      system("heroku run 'bundle exec rake bower:install' --app #{ENVIRONMENTS[args[:env] || :staging]}")
    end

    puts "Deployment Complete"
  end

  task :update_code, :env, :branch do |t, args|
    puts "Updating #{ENVIRONMENTS[args[:env]]} with branch #{args[:branch]}"
    system("git push #{args[:env]} #{args[:branch]}:master")
  end
end

# encoding: UTF-8

require 'yaml'
require 'fileutils'
require 'pathname'

require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'

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

        puts "Symlinking #{lib_file} -> #{public_file}"
        FileUtils.ln_s(lib_file.expand_path.to_s, public_file.expand_path.to_s, force: true)
      end
    end
  end
end

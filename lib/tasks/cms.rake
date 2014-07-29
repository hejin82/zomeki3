# encoding: utf-8
namespace :cms do
  namespace :cms do
    desc 'Clean static files'
    task(:clean_statics => :environment) do
      clean_feeds
      clean_statics('r')
      clean_statics('mp3')
    end

    namespace :feeds do
      desc 'Read feeds'
      task(:read => :environment) do
        Script.run('cms/script/feeds/read')
      end
    end

    namespace :link_check do
      desc 'Check links.'
      task(:check => :environment) do
        Util::LinkChecker.check
      end
    end

    namespace :nodes do
      desc 'Publish nodes'
      task(:publish => :environment) do
        Script.run('cms/script/nodes/publish')
      end

      desc 'Publish all nodes'
      task(:publish_all => :environment) do
        Script.run('cms/script/nodes/publish?all=all')
      end
    end

    namespace :talks do
      desc 'Exec talk tasks'
      task(:exec => :environment) do
        Script.run('cms/script/talk_tasks/exec')
      end
    end
  end
end

def clean_feeds
  Dir["#{Rails.root.join('sites')}/**/{feed,index}.{atom,rss}"].each do |file|
    info_log "DELETED: #{file}"
    File.delete(file)
  end
end

def clean_statics(base_ext)
  Dir["#{Rails.root.join('sites')}/**/*.html.#{base_ext}"].each do |base_file|
    ['', '.r', '.mp3'].each do |ext|
      next unless File.exist?(file = base_file.sub(Regexp.new("\.#{base_ext}$"), ext))
      info_log "DELETED: #{file}"
      File.delete(file)
    end
  end
end

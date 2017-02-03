class Script
  cattr_reader :options

  def self.run_from_web(path, options = {})
    ## reset
    if proc = Sys::Process.find_by(name: path)
      raise "プロセスが既に実行されています。" if proc.state == "running"
      proc.attributes = {
        :state      => nil,
        :user_id    => Core.user.id,
        :site_id    => Core.site.try(:id),
        :started_at => nil,
        :closed_at  => nil,
        :interrupt  => nil,
        :total      => 0,
        :current    => 0,
        :success    => 0,
        :error      => 0,
        :message    => nil,
      }
      proc.save
    end
    ## run
    ruby   = "#{RbConfig::CONFIG["bindir"]}/ruby"
    runner = "#{Rails.root}/bin/rails runner"
    opts   = options.inspect
    cmd    = "#{ruby} #{runner} -e #{Rails.env} \"Script.run('#{path}', #{opts})\""
    system("#{cmd} >/dev/null &")

    return true
  end

  def self.run(path, options = {})
    @@kill     = 10800 # sec
    @@path     = path
    @@proc     = nil
    @@time     = nil
    @@options  = options
    @@success  = 0
    @@reflesh  = 10

    ENV['INPUTRC'] ||= '/etc/inputrc'

    ## locked
    if !self.lock
      puts "already running"
      return "already running"
    end

    ## start
    start = Time.now
    self.log "[#{start.strftime('%Y-%m-%d %H:%M:%S')}] script:#{@@path} ... start"

    ## dispatch
    uri = URI.parse(path)
    script = "#{File.dirname(uri.path).camelize}Script".constantize
    method = File.basename(uri.path)
    params = Rack::Utils.parse_nested_query(uri.query)
    script.new(params).public_send(method)
    self.log "success " + "#{@@proc.success}" + (@@proc.total ? "/#{@@proc.total}" : "")

    ## finish
    finish = Time.now
    past   = sprintf('%.2f', finish - start)
    self.log "[#{finish.strftime('%Y-%m-%d %H:%M:%S')}] script:#{@@path} ... finished (#{past} sec)"
    self.unlock

  rescue Exception => e
    self.error e
    self.error e.backtrace.slice(0, 20).join("\n")
    self.unlock
  end

  def self.total(num = 1)
    return unless defined? @@proc
    if num.is_a?(Fixnum)
      @@proc.total += num
    else
      @@proc.total = nil
    end
    if num != 1
      @@proc.updated_at = DateTime.now
      @@proc.save
    end
    return @@proc.total
  end

  def self.current(num = 1)
    return unless defined? @@proc
    @@proc.current += num
    if (@@proc.current % @@reflesh) == 0
      value = @@proc.interrupted?
      raise InterruptException.new(value) if value == "stop"
    end
    if @@proc.current >= @@proc.current_was + 100
      @@proc.save
    end
    return @@proc.current
  end

  def self.success(num = 1)
    return unless defined? @@proc
    @@proc.success += num
    if num > 0 && (@@proc.success % @@reflesh) == 0
      @@proc.updated_at = DateTime.now
      @@proc.save
    end
    return @@proc.success
  end

  def self.error(message = nil)
    return unless defined? @@proc
    if message
      @@proc.error += 1
      self.log "Error: #{message}"
    end
    return @@proc.error
  end

  def self.log(message)
    return unless defined? @@proc
    if !message.blank?
      @@proc.message = "" if @@proc.message.blank?
      @@proc.message += "#{message}\n"
      puts message
    end
    return message
  end

  def self.progress
    self.current
    yield
    self.success
  rescue => e
    self.error e
    error_log e
    error_log e.backtrace.join("\n")
  end

protected

  def self.lock
    @@proc = Sys::Process.lock(:name => @@path, :time_limit => @@kill)
    @@time = @@proc.created_at if @@proc
    @@proc
  end

  def self.keep_lock(attrs = {})
    return false if @@time != @@proc.created_at
    @@proc.updated_at = DateTime.now
    @@proc.attributes = attrs
    @@proc.save
  end

  def self.unlock
    @@proc.unlock if @@proc && @@proc.closed_at.nil?
  end

  class InterruptException < StandardError
    ## interrupt by admin
  end
end


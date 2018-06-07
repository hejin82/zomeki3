class Util::Proc
  class << self
    def fork(options = {})
      ActiveRecord::Base.clear_all_connections!
      pid = Kernel.fork do
        ActiveRecord::Base.establish_connection
        yield
      end
      Process.detach(pid) if options[:detach] && pid
      pid
    end
  end
end

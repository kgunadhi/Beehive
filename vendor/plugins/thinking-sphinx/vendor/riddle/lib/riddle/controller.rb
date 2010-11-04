module Riddle
  class Controller
    attr_accessor :path, :bin_path, :searchd_binary_name, :indexer_binary_name
    
    def initialize(configuration, path)
      @configuration  = configuration
      @path           = path
      
      @bin_path            = ''
      @searchd_binary_name = 'searchd'
      @indexer_binary_name = 'indexer'
    end
    
    def sphinx_version
      `***REMOVED***{indexer} 2>&1`[/^Sphinx (\d+\.\d+(\.\d+|\-beta))/, 1]
    rescue
      nil
    end
    
    def index(*indexes)
      options = indexes.last.is_a?(Hash) ? indexes.pop : {}
      indexes << '--all' if indexes.empty?
      
      cmd = "***REMOVED***{indexer} --config \"***REMOVED***{@path}\" ***REMOVED***{indexes.join(' ')}"
      cmd << " --rotate" if running?
      options[:verbose] ? system(cmd) : `***REMOVED***{cmd}`
    end
    
    def start
      return if running?
      
      cmd = "***REMOVED***{searchd} --pidfile --config \"***REMOVED***{@path}\""
      
      if RUBY_PLATFORM =~ /mswin/
        system("start /B ***REMOVED***{cmd} 1> NUL 2>&1")
      else
        `***REMOVED***{cmd}`
      end
      
      sleep(1)
      
      unless running?
        puts "Failed to start searchd daemon. Check ***REMOVED***{@configuration.searchd.log}."
      end
    end
    
    def stop
      return true unless running?
      Process.kill('SIGTERM', pid.to_i)
    rescue Errno::EINVAL
      Process.kill('SIGKILL', pid.to_i)
    ensure
      return !running?
    end
    
    def pid
      if File.exists?(@configuration.searchd.pid_file)
        File.read(@configuration.searchd.pid_file)[/\d+/]
      else
        nil
      end
    end
    
    def running?
      !!pid && !!Process.kill(0, pid.to_i)
    rescue
      false
    end
    
    private
    
    def indexer
      "***REMOVED***{bin_path}***REMOVED***{indexer_binary_name}"
    end
    
    def searchd
      "***REMOVED***{bin_path}***REMOVED***{searchd_binary_name}"
    end
  end
end

module MongoManager
  module Helper
    extend self

    def spawn(*cmd)
      if pid = fork
        Process.wait(pid)
        if $?.exitstatus != 0
          raise SpawnError, "Exited with code #{$?.exitstatus}"
        end
      else
        exec(*cmd)
      end
    end

    def spawn_mongo(bin_path, log_path, pid_file_path, *args)
      expanded_cmd = [
        bin_path,
        '--logpath', log_path,
        '--pidfilepath', pid_file_path,
        '--fork',
      ] + args
      puts("Execute #{join_command(expanded_cmd)}")
      spawn(*expanded_cmd)
    rescue SpawnError => e
      if File.exist?(log_path)
        lines = File.read(log_path).split("\n")
        start = [20, lines.length].min
        if start > 0
          lines = lines[-start..-1]
          extra = "last 20 log lines from #{log_path}:\n#{lines.join("\n")}"
          raise SpawnError, "#{e}; #{extra}"
        else
          raise SpawnError, "#{e}; log file #{log_path} empty"
        end
      else
        extra = "log file #{log_path} does not exist"
        if File.exist?(dir = File.dirname(log_path))
          extra << "; directory #{dir} exists"
        else
          extra << "; directory #{dir} does not exist either"
        end
        raise SpawnError, "#{e}; #{extra}"
      end
    end

    def join_command(cmd)
      cmd.map { |part| "'" + part.gsub("'", "\\'") + "'" }.join(' ')
    end
  end
end

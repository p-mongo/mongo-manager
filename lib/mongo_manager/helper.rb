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
      extra = excerpt_log_file(log_path)
      raise SpawnError, "#{e}; #{extra}"
    end

    def join_command(cmd)
      cmd.map { |part| "'" + part.gsub("'", "\\'") + "'" }.join(' ')
    end

    def excerpt_log_file(log_path)
      if File.exist?(log_path)
        lines = File.read(log_path).split("\n")
        start = [20, lines.length].min
        if start > 0
          lines = lines[-start..-1]
          "last 20 log lines from #{log_path}:\n#{lines.join("\n")}"
        else
          "log file #{log_path} empty"
        end
      else
        excerpt = "log file #{log_path} does not exist"
        if File.exist?(dir = File.dirname(log_path))
          excerpt << "; directory #{dir} exists"
        else
          excerpt << "; directory #{dir} does not exist either"
        end
        excerpt
      end
    end

    def create_key(key_file_path)
      File.open(key_file_path, 'w') do |f|
        f << Base64.encode64(OpenSSL::Random.random_bytes(756))
      end
      FileUtils.chmod(0600, key_file_path)
    end
  end
end

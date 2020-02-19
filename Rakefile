task default: :test

def run(cmd)
  if pid = fork
    pid, status = Process.wait2(pid)
    if status.exitstatus != 0
      exit status.exitstatus
    end
  else
    exec(*cmd)
  end
end

task :test do
  run(%w(docker build -t mongo-manager .))
  run(%w(docker run --tmpfs /db:exec --init -it mongo-manager))
end

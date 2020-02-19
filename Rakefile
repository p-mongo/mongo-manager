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

task :build do
  run(%w(docker build -t mongo-manager .))
end

task test: :build do
  run(%w(docker run --tmpfs /db:exec --init -it mongo-manager))
end

namespace :test do
  task unit: :build do
    run(%w(docker run --tmpfs /db:exec --init -it mongo-manager rspec spec/mongo_manager))
  end

  task api: :build do
    run(%w(docker run --tmpfs /db:exec --init -it mongo-manager rspec spec/integration/api))
  end

  task cmd: :build do
    run(%w(docker run --tmpfs /db:exec --init -it mongo-manager rspec spec/integration/cmd))
  end
end

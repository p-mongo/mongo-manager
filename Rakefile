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

TEST_COMMAND = %w(docker run --tmpfs /db:exec --init -it mongo-manager).freeze

task test: %w(test:unit test:api test:cmd)

namespace :test do
  task unit: :build do
    run(TEST_COMMAND + %w(rspec spec/mongo_manager))
  end

  task api: :build do
    run(TEST_COMMAND + %w(rspec spec/integration/api))
  end

  task cmd: :build do
    run(TEST_COMMAND + %w(rspec spec/integration/cmd))
  end
end

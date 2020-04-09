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

desc 'Build the Docker image used for tests'
task :build do
  run(%w(docker build -t mongo-manager .))
end

namespace :build do
  desc 'Build the Docker image used for tests with legacy servers'
  task :legacy do
    run(%w(docker build -f Dockerfile.legacy -t mongo-manager-legacy .))
  end
end

TEST_COMMAND = %w(docker run --tmpfs /db:exec --init -it mongo-manager).freeze
LEGACY_TEST_COMMAND = %w(docker run --tmpfs /db:exec --init -it mongo-manager-legacy).freeze

desc 'Run all tests'
task test: %w(test:unit test:api test:cmd test:legacy)

namespace :test do
  desc 'Run unit tests'
  task unit: :build do
    run(TEST_COMMAND + %w(rspec -f Rfc::Aif spec/mongo_manager))
  end

  desc 'Run integration tests for the library'
  task api: :build do
    run(TEST_COMMAND + %w(rspec -f Rfc::Aif
      spec/integration/api/init_spec.rb
      spec/integration/api/init_modern_spec.rb
    ))
  end

  desc 'Run integration tests for the command-line tool'
  task cmd: :build do
    run(TEST_COMMAND + %w(rspec -f Rfc::Aif spec/integration/cmd))
  end

  desc 'Run integration tests for the library with legacy servers'
  task legacy: 'build:legacy' do
    run(LEGACY_TEST_COMMAND + %w(rspec -f Rfc::Aif
      spec/integration/api/init_spec.rb
      spec/integration/api/init_legacy_spec.rb
    ))
  end
end

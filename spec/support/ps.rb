module Ps
  module_function def mongod
    get_pids('mongod')
  end

  module_function def mongos
    get_pids('mongos')
  end

  module_function def get_pids(bin_basename)
    `pgrep -x #{bin_basename}`.split(/\s+/).compact.map(&:to_i)
  end

  module_function def get_cmdline(pid, bin_basename)
    `ps awwxu |egrep '\\b#{pid}\\b' |grep -v grep |grep #{bin_basename}`
  end
end

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
end

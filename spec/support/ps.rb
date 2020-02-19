module Ps
  module_function def mongod
    `pgrep -x mongod`.split(/\s+/).compact.map(&:to_i)
  end

  module_function def mongos
    `pgrep -x mongos`.split(/\s+/).compact.map(&:to_i)
  end
end

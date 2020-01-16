require "active_support/inflector/inflections"
require "active_support/core_ext/string/inflections"
require "active_support/inflector/singleton"
require "active_support/inflector/default_inflections"

module ActiveSupport
  module Inflector
    class Instance
      include DefaultInflections
    end

    instance.apply_default_inflections!
  end
end

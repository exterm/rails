require "active_support/inflector/instance"
require "active_support/inflector/inflections"
require "active_support/core_ext/string/inflections"

module ActiveSupport
  module Inflector
    class << self
      def instance
        @instance ||= Instance.new
      end

      private
        def respond_to_missing?(name, include_private = false)
          instance.respond_to?(name, include_private)
        end

        def method_missing(method, *args, &block)
          instance.public_send(method, *args, &block)
        end
    end
  end
end

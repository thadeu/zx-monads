# frozen_string_literal: true

module Zx
  class Steps
    include Zx::Maybeable

    class << self
      def step(step)
        steps << step
      end

      def steps
        @steps ||= []
      end
    end

    def call
      list = self.class.steps
      list.reduce(Some()) { |result, step| result >> send(step) }
    end
  end
end

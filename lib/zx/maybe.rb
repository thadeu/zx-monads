# frozen_string_literal: true
module Zx
  module Maybe
    module Maybeable
      None = ->(*kwargs) { ::Maybe::None.new(*kwargs) }
      Some = ->(*kwargs) { ::Maybe::Some.new(*kwargs) }
      Maybe = ->(*kwargs) { ::Maybe.of(*kwargs) }
      
      def Maybe(*kwargs)
        ::Maybe.of(*kwargs)
      end
      
      def Some(*kwargs)
        ::Maybe::Some.new(*kwargs)
      end
  
      def None(*kwargs)
        ::Maybe::None.new(*kwargs)
      end

      def Try(default = nil, options = {})
        Some yield
      rescue StandardError => e
        None[default || options.fetch(:or, nil)]
      end
    end

    def self.included(klass)
      klass.include(Maybeable)
      klass.extend(Maybeable)
    end
  end
end
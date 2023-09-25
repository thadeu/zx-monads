# frozen_string_literal: true
module Zx
  module Either
    module Eitherable
      Left = ->(*kwargs) { ::Either::Left.new(*kwargs) }
      Right = ->(*kwargs) { ::Either::Right.new(*kwargs) }
      
      def Right(*kwargs)
        ::Either::Right.new(*kwargs)
      end
  
      def Left(*kwargs)
        ::Either::Left.new(*kwargs)
      end

      def Try(default = nil, options = {})
        Right yield
      rescue StandardError => e
        Left default || options.fetch(:or, nil)
      end
    end
  
    def self.included(klass)
      klass.include(Eitherable)
    end
  end

  include Either
end
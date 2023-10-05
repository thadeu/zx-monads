# frozen_string_literal: true

module Zx
  class Maybe
    attr_reader :value

    IsBlank = ->(value) { value.nil? || value.to_s.strip&.empty? || !value }

    def self.of(...)
      new.of(...)
    end

    def self.[](...)
      of(...)
    end

    def of(value)
      return None.new if IsBlank[value]

      Some.new(value)
    rescue StandardError
      None.new
    end

    def type
      to_s.downcase.to_sym
    end

    def some?
      type == :some
    end

    def none?
      type == :none
    end

    def unwrap
      @value
    end

    def or(value)
      IsBlank[@value] ? value : @value
    end

    def >>(other)
      self > other
    end
    alias | >>

    def fmap(_)
      self
    end

    def >(_other)
      self
    end

    def map(arg = nil, &block)
      return Maybe[block.call(@value)] if block_given?
      return Maybe[arg.arity > 1 ? arg.curry.call(@value) : arg.call(@value)] if arg.respond_to?(:call)

      case arg
      in None then self
      in Symbol | String then dig(arg)
      end
    rescue StandardError => e
      None.new(e.message)
    end
    alias apply map

    def map!(&block)
      @value = block.call(@value)

      Maybe[@value]
    end

    def apply!(...)
      apply(...).unwrap
    end

    def dig(...)
      Maybe[@value&.dig(...)]
    end

    def dig!(...)
      dig(...).unwrap
    end

    def match(some:, none:)
      case self
      in Some then some.call(@value)
      else none.call
      end
    end

    def on_success(&block)
      return self if none?

      block.call(Some[@value])

      self
    end

    def on_failure(&block)
      return self if some?

      block.call(None[@value])

      self
    end

    def on(ontype, &block)
      case ontype.to_sym
      when :success then on_success(&block)
      when :failure then on_failure(&block)
      end
    end

    class Some < Maybe
      def self.[](...)
        new(...)
      end

      def initialize(value = nil)
        @value = value
      end

      def deconstruct
        [@value]
      end

      def inspect
        format("#<Zx::Maybe::#{self}:0x%x value=%s>", object_id, @value.inspect)
      end

      def to_s
        'Some'
      end

      def >(other)
        other.respond_to?(:call) ? other.call(@value) : other
      end

      def fmap(&block)
        Maybe[block.call(@value)]
      end
    end

    class None < Maybe
      def self.[](...)
        new(...)
      end

      def initialize(value = nil)
        @value = value
      end

      def deconstruct
        [nil]
      end

      def inspect
        format("#<Zx::Maybe::#{self}:0x%x value=%s>", object_id, @value.inspect)
      end

      def to_s
        'None'
      end

      def map
        self
      end
    end

    module ClassMethods
      None = ->(*kwargs) { Zx::Maybe::None.new(*kwargs) }
      Some = ->(*kwargs) { Zx::Maybe::Some.new(*kwargs) }
      Maybe = ->(*kwargs) { Zx::Maybe.of(*kwargs) }

      def Maybe(*kwargs)
        Zx::Maybe.of(*kwargs)
      end

      def Some(*kwargs)
        Zx::Maybe::Some.new(*kwargs)
      end

      def None(*kwargs)
        Zx::Maybe::None.new(*kwargs)
      end

      def Try(default = nil, options = {})
        Some[yield]
      rescue StandardError => e
        None[default || options.fetch(:or, nil)]
      end
    end
  end
end

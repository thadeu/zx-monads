# frozen_string_literal: true

class Either
  class ArgumentError < ArgumentError
  end

  class ValueError < ArgumentError
  end

  def self.[](...)
    new(...)
  end

  def success?
    raise NotImplementedError
  end

  def failure?
    !success?
  end

  def value!
    @value || raise(ValueError, 'value is empty')
  end

  def on_success(&block)
    return self if failure?

    block.call(@value)

    self
  end

  def on_failure(&block)
    return self if success?

    block.call(@value)

    self
  end

  def match(right:, left:)
    case self
    in Right then right.call(@value)
    else left.call(@error)
    end
  end

  class Left < Either
    attr_reader :error

    def initialize(error)
      @error = error
    end

    def deconstruct
      [@error]
    end

    def success?
      false
    end
  end

  class Right < Either
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def deconstruct
      [@value]
    end

    def success?
      true
    end
  end
end

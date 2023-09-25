# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Either do
  it 'using non functional Either' do
    def divide(x, y)
      # x => Integer | Float
      # y => Integer | Float

      raise Either::ArgumentError, 'Cannot divide by 0' if y == 0

      x / y
    end

    expect(divide(10, 2)).to eq(5)

    expect { divide(10, 0) }.to raise_error(Either::ArgumentError, 'Cannot divide by 0')
    # expect { divide('10', 0) }.to raise_error(NoMatchingPatternError)
  end

  context 'using functional Either' do
    def divide(x, y)
      # x => Integer | Float
      # y => Integer | Float

      return Either::Left['Cannot divide by 0'] if y == 0

      Either::Right[x / y]
    rescue StandardError => e
      Either::Left.new('Cannot divide by error')
    end

    context 'Either::Left' do
      it 'receive error when y is zero' do
        result = divide(10, 0)

        expect(result).to be_a(Either::Left)
        expect(result.error).to eq('Cannot divide by 0')
        expect(result.failure?).to be_truthy

        result.match(
          left: ->(error) { expect(error).to eq('Cannot divide by 0') },
          right: ->(value) { expect(value).to eq(5) }
        )
      end

      it 'receive error when x is not a number' do
        result = divide('10', 0)

        expect(result).to be_a(Either::Left)
        # expect(result.error).to eq('Cannot divide by error')
        expect(result.failure?).to be_truthy
      end
    end

    context 'Either::Right' do
      it 'integer expose methods' do
        result = divide(10, 2)

        expect(result).to be_a(Either::Right)
        expect(result.value).to eq(5)
        expect(result.value!).to eq(5)
        expect(result.success?).to be_truthy
        expect(result.failure?).to be_falsey

        result
          .on_success { |value| expect(value).to eq(5) }
      end

      it 'float expose methods' do
        result = divide(10.0, 2.0)

        expect(result).to be_a(Either::Right)
        expect(result.value).to eq(5)
        expect(result.value!).to eq(5)
        expect(result.success?).to be_truthy
        expect(result.failure?).to be_falsey

        result.match(
          left: ->(error) { raise error },
          right: ->(value) { expect(value).to eq(5) }
        )
      end
    end

    context 'deconstruct' do
      def fetch_email(user_id)
        if user_id == 42
          Either::Right.new('john.doe@example.com')
        else
          Either::Left.new("User #{user_id} not found")
        end
      end
      
      def format_email(either_email)
        case either_email
        in Either::Right[email]
          Either::Right.new("Email: #{either_email.value}")
        in left
          left
        end
      end

      it do
        result = format_email(fetch_email(42))
        
        expect(result).to be_a(Either::Right)
        expect(result.value).to eq('Email: john.doe@example.com')
      end
    end
  end
end

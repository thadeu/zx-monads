# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Zx::Steps do
  context '#step' do
    class OrderStep < Zx::Steps
      def initialize(x = nil)
        @x = x
      end

      step :positive?
      step :apply_tax
      step :divide

      def positive?
        return None unless total.is_a?(Integer) || total.is_a?(Float)
        return None if total <= 0

        Some total
      end

      def apply_tax
        Try { @x -= (@x * 0.1) }
      end

      def divide
        Try { @x /= 2 }
      end

      def total
        @x
      end
    end

    it 'integer number immutable' do
      order = OrderStep.new(20)
      result = order.call

      result
        .map { |n| n + 1 }
        .on_success { |some| expect(some.unwrap).to eq(10) }
        .on_failure { |none| expect(none.or(0)).to eq(0) }

      result
        .map { |n| n + 1 }
        .on(:success) { |some| expect(some.unwrap).to eq(10) }
        .on(:failure) { |none| expect(none.or(0)).to eq(0) }

      expect(result).to be_some
      expect(result.unwrap).to eq(9)
    end

    it 'integer number mutable' do
      order = OrderStep.new(20)
      result = order.call

      result
        .map! { |n| n + 1 }
        .on_success { |some| expect(some.unwrap).to eq(10) }
        .on_failure { |none| expect(none.or(0)).to eq(0) }

      expect(result).to be_some
      expect(result.unwrap).to eq(10)
    end

    it 'string number' do
      order = OrderStep.new('20')
      result = order.call

      expect(result).to be_none
      expect(result.or(0)).to eq(0)
    end

    it 'negative number' do
      order = OrderStep.new(-1)
      result = order.call

      expect(result).to be_none
      expect(result.or(0)).to eq(0)
    end

    it 'negative number with listener' do
      order = OrderStep.new(-1)
      result = order.call

      result
        .on_success { raise }
        .on_failure { |none| expect(none.or(0)).to eq(0) }

      expect(result).to be_none
      expect(result.or(0)).to eq(0)
    end
  end

  context '#step with forward' do
    class OrderWithForwardStep
      include Zx::Maybe

      def initialize(x = nil)
        @x = x
      end

      def positive?
        return None unless total.is_a?(Integer) || total.is_a?(Float)
        return None if total <= 0

        Some total
      end

      def apply_tax(_x)
        Try { @x -= (@x * 0.1) }
      end

      def divide(_x)
        Try { @x /= 2 }
      end

      def total
        @x
      end

      def call
        positive?
          .map { |x| x - (x * 0.1) }
          .map { |x| x / 2 }
      end
    end

    it 'integer number immutable' do
      order = OrderWithForwardStep.new(20)
      result = order.call

      # expect(result).to be_some
      expect(result.unwrap).to eq(9)
    end
  end
end

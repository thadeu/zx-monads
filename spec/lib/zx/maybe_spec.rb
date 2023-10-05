# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Zx::Maybe do
  context 'type' do
    it 'some type' do
      expect(Zx::Maybe[1].type).to eq(:some)
    end

    it 'none type' do
      expect(Zx::Maybe[nil].type).to eq(:none)
    end
  end

  context 'some?' do
    it 'should be true' do
      expect(Zx::Maybe[1].some?).to be_truthy
    end

    it 'should be false' do
      expect(Zx::Maybe[nil].some?).to be_falsey
    end
  end

  context 'unwrap' do
    it 'some value' do
      expect(Zx::Maybe[1].unwrap).to eq(1)
    end

    it 'none value' do
      expect(Zx::Maybe[''].unwrap).to eq(nil)
    end
  end

  context 'map' do
    it 'some value' do
      result = Zx::Maybe[1].map { _1 + 2 }

      expect(result).to be_a(Zx::Maybe::Some)
      expect(result.unwrap).to eq(3)
    end

    it 'none value' do
      result = Zx::Maybe[nil].map { _1 + 2 }

      expect(result).to be_a(Zx::Maybe::None)
      expect(result.unwrap).to eq(nil)
    end

    it 'none value when rescue' do
      result = Zx::Maybe[nil].map { raise 'error' }

      expect(result).to be_a(Zx::Maybe::None)
      expect(result.unwrap).to eq(nil)
    end
  end

  context 'inspect' do
    it 'some' do
      result = Zx::Maybe[1] >> proc { Zx::Maybe[_1 + 2] }

      expect(result.inspect).to include('#<Zx::Maybe::Some')
    end

    it 'none' do
      result = Zx::Maybe[nil].map { _1 + 2 }

      expect(result.inspect).to include('#<Zx::Maybe::None')
    end
  end

  context 'of' do
    it 'some value' do
      expect(Zx::Maybe.of(1).or(2)).to eq(1)
    end

    it 'none value' do
      expect(Zx::Maybe.of(' ').or(2)).to eq(2)
    end
  end

  context 'or' do
    it 'some value' do
      expect(Zx::Maybe[1].or(2)).to eq(1)
    end

    it 'none value' do
      expect(Zx::Maybe[''].or(2)).to eq(2)
    end
  end

  it 'should be some' do
    hash = {
      shopping: {
        banana: {
          price: 10.0
        }
      }
    }

    price =  Zx::Maybe[hash]
             .map { _1[:shopping] }
             .map { _1[:banana] }
             .map { _1[:price] }

    expect(price).to be_some
    expect(price.unwrap).to eq(10.0)
  end

  it 'should be else' do
    hash = {
      shopping: {
        banana: {
          price: 10.0
        }
      }
    }

    price = Zx::Maybe[hash]
            .dig(:shopping)
            .dig(:banana)
            .dig(:prices)

    expect(price).to be_none
    expect(price.or(11.5)).to eq(11.5)
  end

  context 'use cases' do
    class Response
      attr_reader :body

      def initialize(new_body)
        @body = Zx::Maybe[new_body]
      end

      def change(new_body)
        @body = Zx::Maybe[new_body]
      end
    end

    it 'some body match' do
      response = Response.new(nil)

      expect(response.body).to be_none

      response.change({ status: 200 })

      response_status = response.body.match(
        some: ->(body) { Zx::Maybe[body].map { _1.fetch(:status) }.unwrap },
        none: -> {}
      )

      expect(response_status).to eq(200)
    end

    it 'none body match' do
      response = Response.new(nil)
      expect(response.body).to be_none

      response.change({ status: ' ' })
    end

    it 'map attribute with empty value' do
      response = Response.new({ status: ' ' })

      response_status = response.body.match(
        some: ->(body) { Zx::Maybe[body].dig(:status).or(400) },
        none: -> { 400 }
      )

      expect(response_status).to eq(400)
    end

    it 'using modules as parameters' do
      dump = JSON.dump({ status: { code: '300' } })
      response = Response.new(dump)

      module StatusCodeUnwrapModule
        def self.call(body)
          Zx::Maybe[body]
            .map { JSON(_1, symbolize_names: true) }
            .dig(:status, :code)
            .apply(&:to_i)
            .unwrap
        end
      end

      response_status = response.body.match(
        some: StatusCodeUnwrapModule,
        none: -> { 400 }
      )

      expect(response_status).to eq(300)
    end

    it 'using modules as parameters' do
      dump = { status: { code: '300' } }
      response = Response.new(dump)

      class StatusCodeUnwrapFail
        def self.call(value)
          Zx::Maybe[value]
            .dig(:status, :code)
            .unwrap
        end
      end

      response_status = Zx::Maybe[response.body.unwrap[:status][:codes]].match(
        some: StatusCodeUnwrapFail,
        none: -> { 400 }
      )

      expect(response_status).to eq(400)
    end

    it 'using composition' do
      sum = ->(x) { Zx::Maybe::Some[x + 1] }
      subtract = ->(x) { Zx::Maybe::Some[x - 1] }

      result = Zx::Maybe[1] >> \
               sum >> \
               subtract

      expect(result.unwrap).to eq(1)
    end

    it 'using composition' do
      sum = ->(x) { Zx::Maybe::Some[x + 1] }
      subtract = ->(_) { Zx::Maybe::None.new }

      result = Zx::Maybe[1] \
        >> sum \
        >> subtract

      expect(result.unwrap).to be_nil
    end

    it 'using composition' do
      class Order
        def self.sum(x)
          Zx::Maybe[{ number: x + 1 }]
        end
      end

      result = Order.sum(1)
                    .dig(:number)
                    .apply(&:to_i)

      expect(result.unwrap).to be(2)
    end

    it 'using composition' do
      class Order
        include Zx::Maybeable

        def self.sum(x)
          new.sum(x)
        end

        def sum(x)
          Try { { number: x + 1 } }
        end
      end

      result = Order.sum(1)
                    .dig(:number)
                    .apply(&:to_i)

      expect(result.unwrap).to be(2)

      class Order2
        include Zx::Maybeable

        def self.sum(x)
          Maybe[{ number: x + 1 }]
        end
      end

      result = Order2.sum(1)
                     .dig(:number)
                     .apply(&:to_i)

      expect(result.unwrap).to be(2)
    end
  end
end

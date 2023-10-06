<p align="center">
  <h1 align="center">🔃 Zx::Monads</h1>
  <p align="center"><i>FP Monads for Ruby</i></p>
</p>

<p align="center">
  <a href="https://rubygems.org/gems/zx-monads">
    <img alt="Gem" src="https://img.shields.io/gem/v/zx-monads.svg">    
  </a>

  <a href="https://github.com/thadeu/zx-monads/actions/workflows/ci.yml">
    <img alt="Build Status" src="https://github.com/thadeu/zx-monads/actions/workflows/ci.yml/badge.svg">
  </a>
</p>


## Motivation

Because in sometimes, we need to handling a safe value for our objects. This gem simplify this work.

## Documentation <!-- omit in toc -->

Version    | Documentation
---------- | -------------
unreleased | https://github.com/thadeu/zx-monads/blob/main/README.md

## Table of Contents <!-- omit in toc -->
  - [Installation](#installation)
  - [Usage](#usage)

## Compatibility

| kind           | branch  | ruby               |
| -------------- | ------- | ------------------ |
| unreleased     | main    | >= 2.7.6, <= 3.2.x |

## Installation

Use bundle

```ruby
bundle add zx-monads
```

or add this line to your application's Gemfile.

```ruby
gem 'zx-monads'
```

and then, require module

```ruby
require 'zx'
```

## Configuration

Without configuration, because we use only Ruby. ❤️

## Usage

How to use in my codebase?

```rb
class Order
  include Zx # include all Zx library.
end

class Order
  include Zx::Maybeable
end

class ProcessOrder < Zx::Steps
  # include Zx::Maybeable included now!
end
```

### Available public methods

```md
#type -> Returns maybe type
#some? -> Returns boolean 
#none? -> Returns boolean 
#unwrap -> Returns value unwrapped
#or(value) -> Returns unwrap or value
#>>(other) -> Forward to another Maybe
#fmap -> Create an step and wrap new value
#map(:key) -> Same the fmap, but receive another parameters
#map(&:method) -> Same the map, but respond to method
#map {} -> Same the the map, but receive an block
#map!{} -> Same the map, but change to new value
#apply!{} -> Same the map! but more legible
#dig(keys) -> Get values using keys like Hash#dig
#dig!(keys) -> Same them dig, but return unwrap
#match(some:, none:) -> Receive callables and associate them
#on_success{} -> Only when Some
#on_failure{} -> Only then None
#on(:success|:failure){}
```

### ZX::Maybe

```ruby
result = Zx::Maybe[1] # or Maybe.of(1)
```

```ruby
result = Zx::Maybe[nil] # or Maybe.of(nil)
```

```ruby
result = Zx::Maybe[1].map{ _1 + 2}
# -> Some(3)
```

```ruby
result = Zx::Maybe[nil].map{ _1 + 2}
# -> None
```

```ruby
result = Zx::Maybe.of(1).or(2)
result.or(2) # 1
```

```ruby
result = Zx::Maybe.of(' ').or(2)
result.or(2) # 2
```

```ruby
result = Zx::Maybe.of(' ').or(2)
result.or(2) # 2
```

```ruby
order = {
  shopping: {
    banana: {
      price: 10.0
    }
  }
}

price =  Zx::Maybe[order]
  .map { _1[:shopping] }
  .map { _1[:banana] }
  .map { _1[:price] }

# -> Some(10.0)

# or using #dig

price =  Zx::Maybe[order].dig(:shopping, :banana, :price)
# -> Some(10.0)

price_none =  Zx::Maybe[order].dig(:shopping, :banana, :price_non_exists)
# -> None

price_or =  Zx::Maybe[order].dig(:shopping, :banana, :price_non_exists).or(10.0)
# -> Some(10.0)
```

```rb
class Response
  attr_reader :body

  def initialize(new_body)
    @body = Zx::Maybe[new_body]
  end

  def change(new_body)
    @body = Zx::Maybe[new_body]
  end
end

response = Response.new(nil)
expect(response.body).to be_none

response.change({ status: 200 })
expect(response.body).to be_some

response_status = response.body.match(
  some: ->(body) { Zx::Maybe[body].map { _1.fetch(:status) }.unwrap },
  none: -> {}
)
```

**Use case, when use to parse response stringify json**

```rb
dump = JSON.dump({ status: { code: '300' } })

response = Response.new(dump) # It's receive an JSON stringified

module StatusCodeUnwrapModule
  def self.call(body)
    Zx::Maybe[body]
      .map{ JSON(_1, symbolize_names: true) }
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
```

You can use `>>` to compose many callables, like this.

```rb
sum = ->(x) { Zx::Maybe::Some[x + 1] }

subtract = ->(x) { Zx::Maybe::Some[x - 1] }

result = Zx::Maybe[1] >> \
  sum >> \
  subtract

expect(result.unwrap).to eq(1)
```

If handle None, no worries.

```rb
sum = ->(x) { Zx::Maybe::Some[x + 1] }

subtract = ->(_) { Zx::Maybe::None.new }

result = Zx::Maybe[1] \
  >> sum \
  >> subtract

expect(result.unwrap).to be_nil
```

```rb
class Order
  def self.sum(x)
    Zx::Maybe[{ number: x + 1 }]
  end
end

result = Order.sum(1)
  .dig(:number)
  .apply(&:to_i)

expect(result.unwrap).to be(2)
```

### Zx::Maybe::Some

```rb
class Order
  include Zx::Maybeable

  def self.sum(x)
    new.sum(x)
  end

  def sum(x)
    Some[{ number: x + 1 }]
  end
end

result = Order.sum(1)
  .dig(:number)
  .apply(&:to_i)

expect(result.unwrap).to be(2)
```

### Zx::Maybe::None

```rb
class Order
  include Zx::Maybeable

  def self.sum(x)
    new.sum(x)
  end

  def sum(x)
    Try {{ number: x + ' ' }}
  end
end

result = Order.sum(1)
number = result.dig(:number).apply(&:to_i)

expect(result).to be_none
expect(result).to be_a(Maybe::None)
expect(number.unwrap).to be(0) # nil.to_i == 0
```

### Zx::Maybe::Try

> Only included or inherited!

```rb
class Order
  include Zx::Maybeable

  def self.sum(x)
    new.sum(x)
  end

  def sum(x)
    Try {{ number: x + 1 }}
  end
end

result = Order.sum(1)
  .dig(:number)
  .apply(&:to_i)

expect(result.unwrap).to be(2)
```

With default value, in None case.

```rb
class Order
  include Zx::Maybeable

  def self.sum(x)
    new.sum(x)
  end

  def sum(x)
    Try(2) {{ number: x + ' ' }}
  end
end

result = Order.sum(1)
  .dig(:number)
  .apply(&:to_i)

expect(result.unwrap).to be(2)
```

```rb
class Order
  include Zx::Maybeable

  def self.sum(x)
    new.sum(x)
  end

  def sum(x)
    Try(or: 1000) {{ number: x + ' ' }}
  end
end

result = Order.sum(1).dig(:number).apply(&:to_i)

expect(result.unwrap).to be(1000)
```

### Zx::Steps

```rb
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
```

```rb
order = OrderStep.new(20)

order.call
  .map { |n| n + 1 }
  .on_success { |some| expect(some.unwrap).to eq(10) }
  .on_failure { |none| expect(none.or(0)).to eq(0) }
```

```rb
order = OrderStep.new(20)

order.call
  .map { |n| n + 1 }
  .on(:success) { |some| expect(some.unwrap).to eq(10) }
  .on(:failure) { |none| expect(none.or(0)).to eq(0) }
```

```rb
order = OrderStep.new(-1)

order.call
  .on_success { raise }
  .on_failure { |none| expect(none.or(0)).to eq(0) }
```

[⬆️ &nbsp;Back to Top](#table-of-contents-)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thadeu/zx-monads. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/thadeu/zx-monads/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

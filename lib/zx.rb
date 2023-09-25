# frozen_string_literal: true

module Zx
  def self.included(klass)
    klass.include(Maybe::Maybeable)
    klass.extend(Maybe::Maybeable)
  end
end

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.setup
loader.eager_load

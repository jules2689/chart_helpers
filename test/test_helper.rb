$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'chart_helpers'

require 'minitest/autorun'
require "mocha/mini_test"

def fixture(file)
  File.read(File.expand_path("../fixtures/#{file}", __FILE__))
end

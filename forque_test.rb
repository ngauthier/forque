require 'test/unit'
require 'forque'

class ForqueTest < Test::Unit::TestCase

  def test_simple_collect
    assert_equal [4,9,16], Forque.new(2,3,4).collect{|x| x**2}.sort
  end

  def test_single_item
    assert_equal [1], Forque.new(1).collect{|i| i }
  end

  def test_concurrent_each
    start = Time.now
    Forque.new(0.1, 0.1, 0.1, 0.1).collect{|i| sleep(i) }
    finish = Time.now
    assert (finish-start) < 0.25
  end

  class MyException < Exception ; end
  def test_exceptions
    assert_raise(MyException) do
      Forque.new(1, 2, 3).collect{|i| raise MyException }
    end
  end


  class MyProcessor
    attr_reader :number
    def initialize(number)
      @number = number
    end

    def process!
      @number = @number ** 2
    end
  end
  def test_custom_class_objects
    two = MyProcessor.new(2)
    three = MyProcessor.new(3)
    four = MyProcessor.new(4)
    results = Forque.new(two, three, four).collect{|p| p.process!; p}.collect(&:number)
    assert_equal [4, 9, 16], results.sort
  end

  def test_multiple_operations
    f = Forque.new(2, 3, 4)
    assert_equal [4, 9, 16], f.collect{|n| n ** 2}.sort
    assert_equal [4, 6, 8], f.collect{|n| n*2}.sort
  end
end

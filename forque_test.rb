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
    Forque.new(0.1, 0.1, 0.1, 0.1).each{|i| sleep(i)}
    finish = Time.now
    assert (finish-start) < 0.25
  end
end

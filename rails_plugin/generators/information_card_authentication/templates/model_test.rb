require File.dirname(__FILE__) + '/../test_helper'

class <%= user_model.camelize %>InformationCardTest < Test::Unit::TestCase
  fixtures :<%= user_model.underscore %>_information_cards

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
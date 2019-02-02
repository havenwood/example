require 'test_helper'

class CustomerControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get customers_url
    assert_response :success
  end

end

require 'test_helper'

class CustomerControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get customer_list_url
    assert_response :success
  end

end

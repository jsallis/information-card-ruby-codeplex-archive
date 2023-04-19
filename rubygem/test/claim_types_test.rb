require 'test_helper'

class ClaimTypesTest < Test::Unit::TestCase
  include InformationCard

  def test_map_should_return_specified_claims
    expected_claims = ["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/mobilephone",
                      "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/privatepersonalidentifier"];
    actual_claims = ClaimTypes.map([:mobile_phone, :ppid])
    assert_equal_arrays(expected_claims, actual_claims) {|x,y| x <=> y}
  end
  
  def test_map_should_raise_exception_if_uknown_claim_specified
   assert_raises("Undefined claim fraggles") do
      ClaimTypes.map([:fraggles])
    end    
  end
  
  def test_map_should_throw_exception_when_no_claim_types_specified
    expected_claims = [];
    actual_claims = ClaimTypes.map([])
    assert_equal_arrays(expected_claims, actual_claims) {|x,y| x <=> y}
  end
  
  def test_lookup_claim_by_attribute_name_and_namespace
    assert_equal :given_name, ClaimTypes.lookup("http://schemas.xmlsoap.org/ws/2005/05/identity/claims", "givenname")
    assert_equal :webpage, ClaimTypes.lookup("http://schemas.xmlsoap.org/ws/2005/05/identity/claims", "webpage")
  end

  def test_lookup_should_raise_exception_if_claim_not_found
    assert_raises("Undefined claim http://schemas.xmlsoap.org/ws/2005/05/identity/claims/fraggles") do
      ClaimTypes.lookup("http://schemas.xmlsoap.org/ws/2005/05/identity/claims", "fraggles")
    end
  end
 
  def test_lookup_should_remove_attribute_name_from_namespace_if_present
    assert_equal :email_address, ClaimTypes.lookup("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress", "emailaddress")    
  end  
end
require 'test_helper'

class SamlTokenTest < Test::Unit::TestCase
  include InformationCard
  
  def setup
    @valid_saml_input = setup_saml_environment('john_smith.xml')    
    @not_before = Time.parse('2007-06-19T05:48:52.906Z')
    @not_on_or_after = Time.parse('2007-06-19T06:48:52.906Z')    
    Config.required_claims = {}
    Config.audience_scope = :page    
  end
     
  def test_should_validate_a_valid_saml_token
    saml_token = SamlToken.create(@valid_saml_input)
    assert saml_token.errors.empty?
    assert saml_token.valid?    
  end  

  def test_should_return_claims
    saml_token = SamlToken.create(@valid_saml_input)
    claims = saml_token.claims    
    expected_claims = {:given_name => 'John', :surname => 'Smith', 
                       :ppid => 'bwicndBxw/6YC029oPv0NWHBbPNMDMoJLQJ6qkofJIg=', 
                       :email_address => 'jsmith@email.com'}
    assert_equal(expected_claims, claims)    
  end
  
  def test_should_return_claims_for_user_with_full_set_of_claims
    saml_token = SamlToken.create(setup_saml_environment('jack_deer.xml'))
    claims = saml_token.claims    
    expected_claims = {:date_of_birth=>"1980-06-19T06:00:00Z", :given_name=>"Jack",
                       :postal_code=>"T3H5R1", :gender=>"1", :email_address=>"jdeer@email.com",
                       :country=>"Canada", :webpage=>"www.informationcardruby.com",
                       :surname=>"Deer", :home_phone=>"403-999-7300", 
                       :ppid=>"NZnC7eVhrZ7DD5ZBp+Cks0JTSPV/nLF3qryWiAJz9G8=",
                       :street_address=>"33 Elk Street", :other_phone=>"403-999-7400", 
                       :locality=>"Calgary", :mobile_phone=>"403-999-7500", 
                       :state_province=>"Alberta"}
    assert_equal(expected_claims, claims)      
  end
  
  def test_should_not_return_claims_if_token_is_invalid
    invalid_saml_input = input_with_xml_element_replaced(@valid_saml_input, "SignatureValue", "invalid signature value")    
    saml_token = SamlToken.create(invalid_saml_input)
    assert_false saml_token.valid?
    assert saml_token.claims.empty?
  end
  
  def test_should_detect_invalid_digest
    valid_digest = "VZkAevzI3Hj9YRG7hW5MD2n/mwg="
    saml_input_with_invalid_digest = input_with_xml_element_replaced(@valid_saml_input, "DigestValue", valid_digest.reverse)
    saml_token = SamlToken.create(saml_input_with_invalid_digest)
    assert_false saml_token.valid?
    assert_equal ["Invalid Digest for #uuid:1ccdbaa7-eeca-4c1b-aacf-4622d08074b6. Expected #{valid_digest} but was #{valid_digest.reverse}"],
      saml_token.errors[:digest]
  end
  
  def test_should_detect_invalid_signature
    saml_input_with_invalid_signature = input_with_xml_element_replaced(@valid_saml_input, "SignatureValue", 'invalid signature value')      
    saml_token = SamlToken.create(saml_input_with_invalid_signature)
    assert_false saml_token.valid?
    assert_equal "Invalid Signature", saml_token.errors[:signature]
  end
    
  def test_should_return_hashed_ppid_for_unique_id_if_identity_claim_is_ppid
    InformationCard::Config.identity_claim = :ppid
    saml_token = SamlToken.create(@valid_saml_input)    
    assert_equal 'c3880b5491ae25aacedbeb5d9a40d5c966d8d84d', saml_token.unique_id
  end
  
  def test_should_return_identity_claim_value_for_unique_id_if_identity_claim_is_not_ppid
    InformationCard::Config.identity_claim = :email_address
    saml_token = SamlToken.create(@valid_saml_input)    
    assert_equal 'jsmith@email.com', saml_token.unique_id    
  end
  
  def test_should_detect_when_current_time_is_before_not_before_condition
    Time.stubs(:now).returns(@not_before - 1)    

    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = {:not_before => "Time is before #{@not_before}"}
    assert_equal expected_error, saml_token.errors[:conditions]
  end  
  
  def test_should_detect_when_current_time_is_after_not_on_or_after_condition
    Time.stubs(:now).returns(@not_on_or_after + 1) 
   
    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = {:not_on_or_after => "Time is on or after #{@not_on_or_after}"}
    assert_equal expected_error, saml_token.errors[:conditions]
  end  

  def test_should_detect_when_current_time_is_on_not_on_or_after_condition
    Time.stubs(:now).returns(@not_on_or_after) 
   
    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = {:not_on_or_after => "Time is on or after #{@not_on_or_after}"}
    assert_equal expected_error, saml_token.errors[:conditions]
  end  

  def test_should_validate_page_level_audience_restriction
    saml_token = SamlToken.create(@valid_saml_input)
    assert saml_token.valid?
    assert saml_token.errors[:audience].nil?
  end
      
  def test_should_detect_page_level_audience_restriction_error
    InformationCard::Config.audiences = ['http://website.com/page1', 'http://website.com/page2']
    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = "AudienceRestriction is not valid"
    assert_equal expected_error, saml_token.errors[:audience]
  end
 
  def test_should_validate_site_level_audience_restriction
    InformationCard::Config.audience_scope = :site
    InformationCard::Config.audiences = ['https://testinformationcardruby.com']
    saml_token = SamlToken.create(@valid_saml_input)
    assert saml_token.valid?
    assert saml_token.errors[:audience].nil?
  end
      
  def test_should_detect_site_level_audience_restriction_error
    InformationCard::Config.audience_scope = :site
    InformationCard::Config.audiences = ['https://someothersite.com']
    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = "AudienceRestriction is not valid"
    assert_equal expected_error, saml_token.errors[:audience]
  end
  
  def test_should_throw_error_if_audiences_are_not_configured
    InformationCard::Config.audiences = []
    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = "AudienceRestriction is not valid"
    assert_equal expected_error, saml_token.errors[:audience] 

    InformationCard::Config.audiences = nil
    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = "AudienceRestriction is not valid"
    assert_equal expected_error, saml_token.errors[:audience]     
  end
     
  def test_should_detect_missing_claim
    Config.required_claims = [:ppid, :mobile_phone]
    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = [:mobile_phone]
    assert_equal expected_error, saml_token.errors[:missing_claims]
  end

  def test_should_detect_missing_multiple_claims
    Config.required_claims = [:ppid, :mobile_phone, :postal_code]
    saml_token = SamlToken.create(@valid_saml_input)
    assert_false saml_token.valid?
    expected_error = [:mobile_phone, :postal_code]
    assert_equal expected_error, saml_token.errors[:missing_claims]
  end  
end
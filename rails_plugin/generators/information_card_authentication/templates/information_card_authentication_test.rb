require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/information_card_authentication'

require 'rubygems'
gem 'mocha'
require 'mocha'
gem 'information_card'
require 'information_card'

require 'ostruct'

class InformationCardAuthenticationTest < Test::Unit::TestCase
  include InformationCardAuthentication::ViewExtensions
  include InformationCard
  
  def setup
    @controller = Class.new do
      include InformationCardAuthentication::ControllerExtensions
    end.new
  end
    
  def test_should_generate_information_card_identifier_if_identity_claim_is_ppid
    InformationCard::Config.identity_claim = :ppid     
    info_card = OpenStruct.new(:unique_id => 'unique id', :ppid => 'vYJ9BrAQrp6pFUHeSJhg/otr8H27jfitzHEnu3ZeK+k=')
    assert_equal 'KHH-2NKP-MJB', information_card_identifier(info_card)
    info_card = OpenStruct.new(:unique_id => 'unique id', :ppid => 'JYL1xKDqjKTi3bfvz/Rp8D1dSc7uAZdz2yR5gCjjfmk=')
    assert_equal 'PVP-APYS-GV7', information_card_identifier(info_card)
  end
  
  def test_should_return_unique_id_if_identity_claim_is_not_ppid
    InformationCard::Config.identity_claim = :email_address     
    info_card = OpenStruct.new(:unique_id => 'jsmith@email.com', :ppid => 'vYJ9BrAQrp6pFUHeSJhg/otr8H27jfitzHEnu3ZeK+k=')
    assert_equal 'jsmith@email.com', information_card_identifier(info_card)  
  end

  def test_should_process_encrypted_information_card
    encrypted_info_card = Object.new
    InformationCard::Processor.expects(:process).with(encrypted_info_card)
    @controller.process_encrypted_information_card(encrypted_info_card)
  end
  
  def test_should_return_successful_if_authenticate_with_information_card_succeeds
    valid_token = IdentityToken.new
    information_card = Object.new
    <%= user_model.camelize %>InformationCard.expects(:find_by_unique_id).returns(information_card)
    assert_authentication(valid_token, :successful, information_card, nil)
  end
  
  def test_should_return_failed_validation_if_authenticate_with_information_card_fails_validation
    token_errors = {:invalid => 'Your token is invalid'}
    invalid_token = InvalidToken.new(token_errors)
    assert_authentication(invalid_token, :failed_validation, nil, token_errors)
  end

  def test_should_return_failed_authentication_if_authenticate_with_information_card_fails_authentication
    valid_token = IdentityToken.new
    <%= user_model.camelize %>InformationCard.expects(:find_by_unique_id).returns(nil)
    assert_authentication(valid_token, :failed_authentication, nil, nil)
  end

  def test_should_return_successful_if_create_information_card_succeeds
    valid_token = IdentityToken.new
    ppid = 'wA+KnezOWCMKX6LmVzSVF9b1im1iZaUVShLA2d+IZtg='
    claims = {:given_name => 'John', :surname => 'Smith', :ppid => ppid, :email_address => 'jsmith@email.com'}    
    valid_token.stubs(:claims).returns(claims)
    valid_token.stubs(:ppid).returns(ppid)
    valid_token.stubs(:unique_id).returns('smitty')
    information_card = <%= user_model.camelize %>InformationCard.new(:unique_id => valid_token.unique_id, :ppid => valid_token.ppid)    
    <%= user_model.camelize %>InformationCard.expects(:find_by_unique_id).returns(nil)
    assert_creation(valid_token, :successful, information_card, claims, nil)
  end

  def test_should_return_duplicate_if_create_information_card_detects_card_already_registered
    valid_token = IdentityToken.new
    information_card = <%= user_model.camelize %>InformationCard.new(:unique_id => 'smitty', :ppid => 'wA+KnezOWCMKX6LmVzSVF9b1im1iZaUVShLA2d+IZtg=')    
    <%= user_model.camelize %>InformationCard.expects(:find_by_unique_id).returns(information_card)
    assert_creation(valid_token, :duplicate, nil, nil, nil)
  end
  
  def test_should_return_failed_if_create_information_card_fails
    token_errors = {:invalid => 'Your token is invalid'}
    invalid_token = InvalidToken.new(token_errors)
    assert_creation(invalid_token, :failed, nil, nil, token_errors)  
  end
  
  def test_should_generate_information_card_claims_markup
    InformationCard::Config.required_claims = [:given_name, :surname, :ppid] 
    
    expected = "<object type=\"application/x-informationcard\" name=\"encrypted_information_card\">" +
               "<param name=\"tokenType\" value=\"http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV1.1\" />" +
               "<param name=\"requiredClaims\" value=\"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname http://schemas.xmlsoap.org/ws/2005/05/identity/claims/privatepersonalidentifier\"/>" +
               "</object>"    
    assert_equal expected, information_card_claims
  end

  def test_should_raise_error_when_generating_information_card_claims_markup_with_no_claims_specified
    InformationCard::Config.required_claims = [] 
    assert_raises("No claims specified") do
      information_card_claims
    end    

  end
    
  private
    
  def assert_authentication(identity_token, expected_status, expected_information_card, expected_errors)
    encrypted_info_card = Object.new
    @controller.stubs(:process_encrypted_information_card).returns(identity_token)
    @controller.authenticate_with_information_card(encrypted_info_card) do |status, information_card, errors|
      assert_equal expected_status, status
      assert_equal expected_information_card, information_card
      assert_equal expected_errors, errors
    end 
  end
  
  def assert_creation(identity_token, expected_status, expected_information_card, expected_claims, expected_errors)
    encrypted_info_card = Object.new
    @controller.stubs(:process_encrypted_information_card).returns(identity_token)
    @controller.create_information_card(encrypted_info_card) do |status, information_card, claims, errors|
      assert_equal expected_status, status
      if not expected_information_card.nil?      
        assert_equal expected_information_card.ppid, information_card.ppid
        assert_equal expected_information_card.unique_id, information_card.unique_id        
      else
        assert_nil information_card
      end
      assert_equal expected_claims, claims
      assert_equal expected_errors, errors
    end 
  end
  
  def assert_raises(arg1 = nil, arg2 = nil)
    expected_error = arg1.is_a?(Exception) ? arg1 : nil
    expected_class = arg1.is_a?(Class) ? arg1 : nil
    expected_message = arg1.is_a?(String) ? arg1 : arg2
    begin 
      yield
      fail "expected error was not raised"
    rescue Test::Unit::AssertionFailedError
      raise
    rescue => e
      raise if e.message == "expected error was not raised"
      assert_equal(expected_error, e) if expected_error
      assert_equal(expected_class, e.class, "Unexpected error type raised") if expected_class
      assert_equal(expected_message, e.message, "Unexpected error message") if expected_message.is_a? String
      assert_matched(expected_message, e.message, "Unexpected error message") if expected_message.is_a? Regexp
    end
  end
  
end
require 'test_helper'

class ProcessorTest < Test::Unit::TestCase
  include InformationCard
  
  def setup
    Config.certificate_location = 'test/fixtures/certificates'
    Config.certificate_subject = '/O=testinformationcardruby.com/CN=testinformationcardruby.com'
    Config.required_claims = [:given_name, :surname, :ppid, :email_address]    
  end

  def test_should_take_encrypted_data_and_return_a_saml_token    
    claims = {:given_name => 'John',
              :surname => 'Smith', 
              :ppid => 'bwicndBxw/6YC029oPv0NWHBbPNMDMoJLQJ6qkofJIg=', 
              :email_address => 'jsmith@email.com'}
    
    setup_saml_environment('john_smith.xml')                                  
    processed_token = Processor.process(load_encrypted_information_card('john_smith.xml'))
    assert processed_token.valid?
    assert_equal claims, processed_token.claims
  end
  
  def test_should_return_invalid_token_if_exception_occurs_during_decryption
    decrypter = Object.new
    decrypter.stubs(:decrypt).raises('problem with decryption')
    Decrypter.stubs(:new).returns(decrypter)
    
    token = Processor.process('invalid token')
    assert token.instance_of?(InvalidToken)
    assert_equal token.errors[:decryption], 'problem with decryption'
  end
  
end
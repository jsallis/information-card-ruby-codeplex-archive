require 'test_helper'

class DecrypterTest < Test::Unit::TestCase
  include InformationCard
       
  def test_should_decrypt_encrypted_xml_token_into_saml_token
    decrypter = Decrypter.new(
      load_encrypted_information_card('john_smith.xml'),certificates_directory,
      '/O=testinformationcardruby.com/CN=testinformationcardruby.com')
    assert_equal load_saml_token('john_smith.xml'), decrypter.decrypt
  end  
end
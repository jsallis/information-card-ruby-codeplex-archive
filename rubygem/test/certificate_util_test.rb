require 'test_helper'

class CertificateUtilTest < Test::Unit::TestCase
  include InformationCard

  def setup
    @cert_directory = File.join(File.dirname(__FILE__), "fixtures/certificates")
  end
  
  def test_private_key_from_certificate_subject
    expected_private_key_content = File.read(File.join(@cert_directory, "test.key"))    
    private_key = CertificateUtil.lookup_private_key(@cert_directory, '/O=testinformationcardruby.com/CN=testinformationcardruby.com')    
    assert_equal expected_private_key_content, private_key.to_s
  end
  
  def test_should_raise_exception_if_certificate_not_found    
    assert_raises("No private key found in ./test/fixtures/certificates/ with subject not_exist") do
      CertificateUtil.lookup_private_key(@cert_directory, 'not_exist')    
    end
  end
end
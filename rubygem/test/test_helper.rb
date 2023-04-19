require 'test/unit'
require "rexml/document"
require File.dirname(__FILE__) + '/../lib/information_card'

require 'rubygems'
gem 'mocha'
require 'stubba'

class Test::Unit::TestCase
  include REXML
  
  def assert_false(condition)
    assert !condition
  end

  def load_encrypted_information_card(file_name)
    File.read File.join(File.dirname(__FILE__), "fixtures/encrypted_information_cards", file_name)
  end

  def load_saml_token(file_name) 
    File.read File.join(File.dirname(__FILE__), "fixtures/saml_tokens", file_name)
  end
  
  def setup_saml_environment(file_name)  
    saml_token = load_saml_token(file_name)
        
    saml_doc = REXML::Document.new(saml_token)
    conditions = REXML::XPath.first(saml_doc, "//saml:Conditions", "saml" => "urn:oasis:names:tc:SAML:1.0:assertion")
    not_before_time = Time.parse(conditions.attributes['NotBefore'])
    Time.stubs(:now).returns(not_before_time) 
    audiences = REXML::XPath.match(saml_doc, "//saml:AudienceRestrictionCondition/saml:Audience", {"saml" => "urn:oasis:names:tc:SAML:1.0:assertion"}) 
    InformationCard::Config.audiences = audiences.collect {|a| a.text}
    InformationCard::Config.audience_scope = :page
        
    saml_token      
  end
    
  def certificates_directory
    File.join(File.dirname(__FILE__), "fixtures/certificates")  
  end
  
  def input_with_xml_element_replaced(xml_string, element, text)
    doc = REXML::Document.new(xml_string)
    node = doc.root.find_first_recursive {|node| node.kind_of? Element and node.name == element }
    node.text = text
    doc.to_s
  end
  
  def assert_equal_arrays(expected, actual)
    actual.sort! {|a,b| yield a, b} if block_given?
    msg = "#{expected.join(',')} expected, but was \n#{actual.join(',')}"
    assert_equal expected.size, actual.size, msg
    assert_equal expected, actual, msg
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

require 'test_helper'

class XmlCanonicalizerTest < Test::Unit::TestCase
  include InformationCard

INPUT_SAML_ASSERTION =
%(<saml:Assertion AssertionID="uuid:324e84c9-29bc-46a5-8775-3efdc6af7312" 
                IssueInstant="2007-04-12T22:44:02.734Z" 
                xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" 
                MinorVersion="1" 
                Issuer="http://schemas.xmlsoap.org/ws/2005/05/identity/issuer/self" 
                MajorVersion="1">
  <saml:Conditions NotBefore="2007-04-12T22:44:02.734Z" NotOnOrAfter="2007-04-12T23:44:02.734Z">
    <saml:AudienceRestrictionCondition>
      <saml:Audience>https://informationcardruby.com/</saml:Audience> 
    </saml:AudienceRestrictionCondition>
  </saml:Conditions>
  <saml:AttributeStatement>
    <saml:Subject>
      <saml:SubjectConfirmation>
        <saml:ConfirmationMethod>urn:oasis:names:tc:SAML:1.0:cm:bearer</saml:ConfirmationMethod> 
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Attribute AttributeName="givenname" AttributeNamespace="http://schemas.xmlsoap.org/ws/2005/05/identity/claims">
      <saml:AttributeValue>John</saml:AttributeValue> 
    </saml:Attribute>
    <saml:Attribute AttributeName="surname" AttributeNamespace="http://schemas.xmlsoap.org/ws/2005/05/identity/claims">
      <saml:AttributeValue>Smith</saml:AttributeValue> 
    </saml:Attribute>
    <saml:Attribute AttributeName="emailaddress" AttributeNamespace="http://schemas.xmlsoap.org/ws/2005/05/identity/claims">
      <saml:AttributeValue>jsmith@email.com</saml:AttributeValue> 
    </saml:Attribute>
    <saml:Attribute AttributeName="privatepersonalidentifier" AttributeNamespace="http://schemas.xmlsoap.org/ws/2005/05/identity/claims">
      <saml:AttributeValue>wA+KnezOWCMKX6LmVzSVF9b1im1iZaUVShLA2d+IZtg=</saml:AttributeValue> 
    </saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>
)

CANONICALIZED_SAML_ASSERTION = 
%(<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" AssertionID="uuid:324e84c9-29bc-46a5-8775-3efdc6af7312" IssueInstant="2007-04-12T22:44:02.734Z" Issuer="http://schemas.xmlsoap.org/ws/2005/05/identity/issuer/self" MajorVersion="1" MinorVersion="1">
  <saml:Conditions NotBefore="2007-04-12T22:44:02.734Z" NotOnOrAfter="2007-04-12T23:44:02.734Z">
    <saml:AudienceRestrictionCondition>
      <saml:Audience>https://informationcardruby.com/</saml:Audience> 
    </saml:AudienceRestrictionCondition>
  </saml:Conditions>
  <saml:AttributeStatement>
    <saml:Subject>
      <saml:SubjectConfirmation>
        <saml:ConfirmationMethod>urn:oasis:names:tc:SAML:1.0:cm:bearer</saml:ConfirmationMethod> 
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Attribute AttributeName="givenname" AttributeNamespace="http://schemas.xmlsoap.org/ws/2005/05/identity/claims">
      <saml:AttributeValue>John</saml:AttributeValue> 
    </saml:Attribute>
    <saml:Attribute AttributeName="surname" AttributeNamespace="http://schemas.xmlsoap.org/ws/2005/05/identity/claims">
      <saml:AttributeValue>Smith</saml:AttributeValue> 
    </saml:Attribute>
    <saml:Attribute AttributeName="emailaddress" AttributeNamespace="http://schemas.xmlsoap.org/ws/2005/05/identity/claims">
      <saml:AttributeValue>jsmith@email.com</saml:AttributeValue> 
    </saml:Attribute>
    <saml:Attribute AttributeName="privatepersonalidentifier" AttributeNamespace="http://schemas.xmlsoap.org/ws/2005/05/identity/claims">
      <saml:AttributeValue>wA+KnezOWCMKX6LmVzSVF9b1im1iZaUVShLA2d+IZtg=</saml:AttributeValue> 
    </saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>)


  def setup  
    @canonicalizer = XmlCanonicalizer.new
  end
  
  def test_should_canonicalize_full_saml_assertion_as_element
    signed_doc = REXML::Document.new(INPUT_SAML_ASSERTION)
    signed_element = REXML::XPath.first(signed_doc, "saml:Assertion")
    assert_equal CANONICALIZED_SAML_ASSERTION, @canonicalizer.canonicalize(signed_element)
  end 

  def test_should_canonicalize_full_saml_assertion_as_document
    assert_xml CANONICALIZED_SAML_ASSERTION, INPUT_SAML_ASSERTION
  end 

  def test_should_convert_line_breaks
    input = "<person>\n<name>John</name>\r\n<age>25</age>\r</person>"
    expected = "<person>\n<name>John</name>\n<age>25</age>\n</person>"
    assert_xml(expected, input)
  end
  
  def test_should_normalize_white_space_between_attribute_values
    input = "<person first=\"Dr. \t\tBob\" last=\"Smit\th\" phone=\"\t555\t 1234\"></person>"
    expected = %(<person first="Dr. Bob" last="Smit h" phone="555 1234"></person>)
    assert_xml(expected, input)
  end
  
  def test_should_preserve_quote_within_node_text
     input = "<person>Mr Bob's Wild Adventure</person>"
     expected = "<person>Mr Bob's Wild Adventure</person>"
     assert_xml(expected, input)
  end
  
  def test_should_preserve_quote_and_normalize_white_space_within_node_text
     input = "<person>Mr Bob'      s Wild Adventure</person>"
     expected = "<person>Mr Bob' s Wild Adventure</person>"
     assert_xml(expected, input)     
  end
    
  def test_should_double_quote_attribute_values
    input = "<product id='1234' name=\"turbine\" xlmns='http://namespace'></product>"
    expected = %(<product id="1234" name="turbine" xlmns="http://namespace"></product>)
    assert_xml(expected, input)  
  end
  
  def test_should_replace_special_character_quote_in_attribute_values
    input = "<person first='John Smith \"JS\"'></person>"
    expected = %(<person first="John Smith &quot;JS&quot;"></person>)
    assert_xml(expected, input)
  end

  def test_should_replace_special_character_amp_in_attribute_values
    input = "<product company=\"Smith & Smith\"></product>"
    expected = %(<product company="Smith &amp; Smith"></product>)
    assert_xml(expected, input) 
  end

  def test_should_replace_special_character_less_than_in_attribute_values
    input = "<product description=\"< 10 pounds\"></product>"
    expected = %(<product description="&lt; 10 pounds"></product>)
    assert_xml(expected, input) 
  end

  def test_should_resolv_entity_references
    input = %(<?xml version="1.0"?><!DOCTYPE person [<!ENTITY comment "This is a person.">]><person><notes>&comment;</notes></person>)
    expected = %(<person><notes>This is a person.</notes></person>)
    assert_xml(expected, input)
  end
  
  def test_should_remove_xml_and_dtd_declarations
    input = %(<?xml version="1.0"?><!DOCTYPE person [<!ATTLIST person name CDATA "None"><!ENTITY comment "This is a person.">]><person name="Bob"></person>)
    expected = %(<person name="Bob"></person>)
    assert_xml(expected, input)
  end

  def test_should_remove_white_space_outside_the_outer_most_element
    input = %(     <person name="Bob"></person>)
    expected = %(<person name="Bob"></person>)
    assert_xml(expected, input)
  end
  
  def test_should_normalize_white_space_in_start_and_end_elements
    input = %(<person    first = "bob"   id="1234" last="smith"  ></person    >)
    expected = %(<person first="bob" id="1234" last="smith"></person>)
    assert_xml(expected, input)         
  end
  
  def test_should_normalize_white_space_in_start_and_end_elements_when_no_attributes_exist
    input = %(<person  ><name  >Bob</name   ></person >)
    expected = %(<person><name>Bob</name></person>)
    assert_xml(expected, input)     
  end

  def test_should_expand_empty_elements
    input = %(<person/>)
    expected = %(<person></person>)
    assert_xml(expected, input)       
  end

  def test_should_expand_empty_elements_with_attributes
    input = %(<person id="1234"/>)
    expected = %(<person id="1234"></person>)
     assert_xml(expected, input)       
  end

  def test_should_remove_unnecessary_namespace_declarations
    input = %(<person xmlns="http://www.mynamespace.com/person"><id>123</id><name xmlns="http://www.mynamespace.com/person">John</name></person>)
    expected = %(<person xmlns="http://www.mynamespace.com/person"><id>123</id><name>John</name></person>)
    assert_xml(expected, input) 
  end
  
  def test_should_order_namespace_declarations_and_attributes
    input = %(<person last="Smith" first="John" xmlns="http://www.mynamespace.com/person"></person>)
    expected = %(<person xmlns="http://www.mynamespace.com/person" first="John" last="Smith"></person>)
    assert_xml(expected, input)
  end
  
  def assert_xml(expected, input)
    assert_equal expected, @canonicalizer.canonicalize(REXML::Document.new(input)) 
  end 
end
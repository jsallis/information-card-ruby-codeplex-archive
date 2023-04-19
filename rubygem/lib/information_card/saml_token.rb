# Portions of this class were inspired by the XmlSecurity::SignedDocument class written by Todd Saxton
# and the 'Self-Issued InfoCard Tutorial and Demo' written by Kim Cameron

require 'rexml/document'
require 'digest/sha1'
require 'base64'

module InformationCard
  class SamlToken < IdentityToken
    include REXML
    
    private :initialize
    
    def self.create(saml_input)
      saml_doc = REXML::Document.new(saml_input)
      saml_token = SamlToken.new(saml_doc) 
           
      saml_token.validate_document_conditions
      saml_token.validate_document_integrity
      return saml_token unless saml_token.valid?
      
      saml_token.process_claims
      saml_token.validate_claims
      
      saml_token
    end

    def initialize(saml_doc)
      super()
      @doc = saml_doc
    end
    
    def unique_id
      identity_claim_value = @claims[InformationCard::Config.identity_claim]
      return identity_claim_value unless InformationCard::Config.identity_claim == :ppid
      
      combined_key = ''
      combined_key << @mod
      combined_key << @exponent
      combined_key << identity_claim_value
      Digest::SHA1.hexdigest(combined_key)
    end
     
    def ppid
      claims[:ppid]
    end
 
    def process_claims            
      attribute_nodes = XPath.match(@doc, "//saml:AttributeStatement/saml:Attribute", {"saml" => Namespaces::SAML_ASSERTION})
      attribute_nodes.each do |node|
        key = ClaimTypes.lookup(node.attributes['AttributeNamespace'], node.attributes['AttributeName'])      
        @claims[key] = XPath.first(node, "saml:AttributeValue", "saml" => Namespaces::SAML_ASSERTION).text        
      end
    end
    
    def validate_claims
      return if Config::required_claims.nil? or Config::required_claims.empty?
      
      claims_errors = []
      Config::required_claims.each { |claim| claims_errors << claim if not @claims.key?(claim) }
      @errors[:missing_claims] = claims_errors unless claims_errors.empty?
    end
        
    def validate_document_conditions
      validate_audiences
      validate_conditions
    end
    
    def validate_document_integrity
      verify_digest
      verify_signature     
    end
    
    def validate_audiences
      conditions = XPath.first(@doc, "//saml:Conditions", "saml" => Namespaces::SAML_ASSERTION)
      audiences = XPath.match(@doc, "//saml:AudienceRestrictionCondition/saml:Audience", {"saml" => Namespaces::SAML_ASSERTION})
      @errors[:audience] = "AudienceRestriction is not valid" unless valid_audiences?(audiences)      
    end
    
    def validate_conditions    
      conditions = XPath.first(@doc, "//saml:Conditions", "saml" => Namespaces::SAML_ASSERTION)
  
      condition_errors = {}
      not_before_time = Time.parse(conditions.attributes['NotBefore'])
      condition_errors[:not_before] = "Time is before #{not_before_time}" if Time.now < not_before_time     
  
      not_on_or_after_time = Time.parse(conditions.attributes['NotOnOrAfter'])
      condition_errors[:not_on_or_after] = "Time is on or after #{not_on_or_after_time}" if Time.now >= not_on_or_after_time

      @errors[:conditions] = condition_errors unless condition_errors.empty?    
    end
    
    def verify_digest     
      working_doc = REXML::Document.new(@doc.to_s)
      
      assertion_node = XPath.first(working_doc, "saml:Assertion", {"saml" => Namespaces::SAML_ASSERTION}) 
      signature_node =  XPath.first(assertion_node, "ds:Signature", {"ds" => Namespaces::DS}) 
      signed_info_node = XPath.first(signature_node, "ds:SignedInfo", {"ds" => Namespaces::DS})    
      digest_value_node = XPath.first(signed_info_node, "ds:Reference/ds:DigestValue", {"ds" => Namespaces::DS})
      
      digest_value = digest_value_node.text

      signature_node.remove
      digest_errors = []
      canonicalizer = InformationCard::XmlCanonicalizer.new
      
      reference_nodes = XPath.match(signed_info_node, "ds:Reference", {"ds" => Namespaces::DS})
      # TODO: Check specification to see if digest is required.
      @errors[:digest] = "No reference nodes to check digest" and return if reference_nodes.nil? or reference_nodes.empty?
      
      reference_nodes.each do |node|
        uri = node.attributes['URI']
        nodes_to_verify = XPath.match(working_doc, "saml:Assertion[@AssertionID='#{uri[1..uri.size]}']", {"saml" => Namespaces::SAML_ASSERTION})
  
        nodes_to_verify.each do |node|
          canonicalized_signed_info = canonicalizer.canonicalize(node)          
          signed_node_hash = Base64.encode64(Digest::SHA1.digest(canonicalized_signed_info)).chomp                    
          digest_errors << "Invalid Digest for #{uri}. Expected #{signed_node_hash} but was #{digest_value}" unless signed_node_hash == digest_value
        end
                       
        @errors[:digest] = digest_errors unless digest_errors.empty?
      end  
    end
    
    def verify_signature
      assertion_node = XPath.first(@doc, "saml:Assertion", {"saml" => Namespaces::SAML_ASSERTION}) 
      signature_node =  XPath.first(assertion_node, "ds:Signature", {"ds" => Namespaces::DS})    
      modulus_node = XPath.first(signature_node, "ds:KeyInfo/ds:KeyValue/ds:RSAKeyValue/ds:Modulus", {"ds" => Namespaces::DS})
      exponent_node = XPath.first(signature_node, "ds:KeyInfo/ds:KeyValue/ds:RSAKeyValue/ds:Exponent", {"ds" => Namespaces::DS})
      
      @mod = modulus_node.text
      @exponent = exponent_node.text
      public_key_string = get_public_key(@mod, @exponent)
    
      signed_info_node = XPath.first(signature_node, "ds:SignedInfo", {"ds" => Namespaces::DS})
      signature_value_node = XPath.first(signature_node, "ds:SignatureValue", {"ds" => Namespaces::DS})

      signature = Base64.decode64(signature_value_node.text)
      canonicalized_signed_info = InformationCard::XmlCanonicalizer.new.canonicalize(signed_info_node)
      
      @errors[:signature] = "Invalid Signature" unless public_key_string.verify(OpenSSL::Digest::SHA1.new, signature, canonicalized_signed_info)  
    end
    
    def valid_audiences?(audiences)
      audience_scope = InformationCard::Config.audience_scope
      registered_audiences = InformationCard::Config.audiences
      
      return false if registered_audiences.nil? or registered_audiences.empty?
      
      if audience_scope == :page
        audiences.each{|audience| return true if registered_audiences.include?(audience.text)}
      elsif audience_scope == :site
        audiences.each do |audience|
          registered_audiences.each do |registered_audience|
            return true if audience.text.index(registered_audience) == 0
          end
        end
      end      
      false
    end
      
    def get_public_key(mod, exponent)
      mod_binary = Base64.decode64(mod)     
      exponent_binary = Base64.decode64(exponent)
     
      exponent_encoding = make_asn_segment(0x02, exponent_binary)
      modulusEncoding = make_asn_segment(0x02, mod_binary)
      sequenceEncoding = make_asn_segment(0x30, modulusEncoding + exponent_encoding)
      bitstringEncoding = make_asn_segment(0x03, sequenceEncoding)
      hex_array = []
      "300D06092A864886F70D0101010500".gsub(/../) { |m| hex_array << m.to_i(16) }
      rsaAlgorithmIdentifier = hex_array.pack('C*')       
      combined = rsaAlgorithmIdentifier + bitstringEncoding
      publicKeyInfo = make_asn_segment(0x30, rsaAlgorithmIdentifier + bitstringEncoding)
  
      #encode the publicKeyInfo in base64 and add PEM brackets
      public_key_64 = Base64.encode64(publicKeyInfo)
      encoding = "-----BEGIN PUBLIC KEY-----\n"
      offset = 0;
      # strip out the newlines
      public_key_64.delete!("=\n") 
      while (segment = public_key_64[offset, 64])
         encoding = encoding + segment + "\n"
         offset += 64
      end
      encoding = encoding + "-----END PUBLIC KEY-----\n"
      @pub_key = OpenSSL::PKey::RSA.new(encoding)
      @pub_key
    end
    
    def make_asn_segment(type, string)
      case (type)
        when 0x02
          string = 0.chr + string if string[0] > 0x7f
        when 0x03
          string = 0.chr + string
      end
      length = string.length
      
      if (length < 128)
         output = sprintf("%c%c%s", type, length, string)   
      elsif (length < 0x0100)
         output = sprintf("%c%c%c%s", type, 0x81, length, string)    
      elsif (length < 0x010000)
         output = sprintf("%c%c%c%c%s", type, 0x82, length/0x0100, length%0x0100, string)    
      else
          output = nil
      end    
      output
    end
  end
end
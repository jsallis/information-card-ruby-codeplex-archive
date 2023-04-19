require 'digest/sha1'
require 'base64'

module InformationCardAuthentication

  module Common  
    # Generates the Site Specific ID to match the one provided by the Windows CardSpace Identity Selector.
    def information_card_identifier(information_card)
      return information_card.unique_id unless InformationCard::Config.identity_claim == :ppid
      
      character_map = 'QL23456789ABCDEFGHJKMNPRSTUVWXYZ'
      
      hashed = Digest::SHA1.hexdigest(Base64.decode64(information_card.ppid))
      two_byte_brownies = []
      hashed.gsub(/../) { |m| two_byte_brownies << m.to_i(16) }
      
      call_sign = ''
      for i in 0..9
        call_sign << '-' if (i == 3 or i == 7)
        call_sign << (character_map[two_byte_brownies[i] % character_map.length])
      end
      call_sign
    end
  end
  
  module ViewExtensions
    include InformationCardAuthentication::Common
    
    def information_card_claims
      claims = InformationCard::Config.required_claims      
      raise "No claims specified" if claims.blank? or claims.compact.blank?
      
      output = "<object type=\"application/x-informationcard\" name=\"encrypted_information_card\">"
      output << "<param name=\"tokenType\" value=\"http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV1.1\" />"    
      output << "<param name=\"requiredClaims\" value=\"#{InformationCard::ClaimTypes.map(claims).join(' ')}\"/>"
      output << "</object>"
      output
    end
  end
  
  module ControllerExtensions
    include InformationCardAuthentication::Common
    
    def authenticate_with_information_card(encrypted_information_card)      
      identity_token = process_encrypted_information_card(encrypted_information_card)
      if not identity_token.valid?
        yield :failed_validation, nil, identity_token.errors
        return 
      end
      information_card = <%= user_model.camelize %>InformationCard.find_by_unique_id(identity_token.unique_id)      
      if (information_card.nil?)      
        yield :failed_authentication, nil, nil
      else
        yield :successful, information_card, nil
      end    
    end
    
    def create_information_card(encrypted_information_card)
      identity_token = process_encrypted_information_card(encrypted_information_card)
      if not identity_token.valid?
        yield :failed, nil, nil, identity_token.errors 
      elsif <%= user_model.camelize %>InformationCard.find_by_unique_id(identity_token.unique_id)
        yield :duplicate, nil, nil, nil 
      else
        yield :successful, <%= user_model.camelize %>InformationCard.new(:unique_id => identity_token.unique_id, :ppid => identity_token.ppid), identity_token.claims, nil
      end
    end
    
    def process_encrypted_information_card(encrypted_information_card)
      InformationCard::Processor.process(encrypted_information_card)      
    end     
  end 
end

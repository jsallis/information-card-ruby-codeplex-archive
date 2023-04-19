module InformationCard
  class ClaimTypes
  
    @@claims = {
      :given_name => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
      :email_address => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
      :surname => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname",
      :street_address => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/streetaddress",
      :locality => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/locality",
      :state_province => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/stateorprovince",
      :postal_code => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/postalcode",
      :country => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/country",
      :home_phone => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/homephone",
      :other_phone => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/otherphone",
      :mobile_phone => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/mobilephone",
      :date_of_birth => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/dateofbirth",
      :gender => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/gender",
      :ppid => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/privatepersonalidentifier",
      :webpage => "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/webpage"
    }
  
    def self.map(specified_claims)
      values = []    
      specified_claims.each do |claim_key|
        raise "Undefined claim #{claim_key}" if not @@claims.include?(claim_key) 
        values << @@claims[claim_key]
      end
      values
    end
    
    def self.lookup(namespace, attribute_name)
      # Some identity selector implementations specify the attribute name as part of the namespace.
      # As a result, we need to remove the duplicated attribute name from the namespace.
      # ex. namespace => http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
      #     attribute_name => emailaddress
      desired_claim = "#{namespace}/#{attribute_name}".gsub(/#{attribute_name}\/#{attribute_name}/, attribute_name) 
      @@claims.each_pair do |key, value|
        return key if value == desired_claim
      end
      raise "Undefined claim #{desired_claim}"
    end
  end
end

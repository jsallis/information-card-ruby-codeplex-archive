module InformationCard   
  class Config
    def self.certificate_location=(certificate_location)
      @certificate_location = certificate_location
    end
    
    def self.certificate_location
      @certificate_location
    end    

    def self.certificate_subject=(certificate_subject)
      @certificate_subject = certificate_subject
    end
    
    def self.certificate_subject
      @certificate_subject
    end    

    def self.audience_scope=(audience_scope)
      @audience_scope = audience_scope
    end
    
    def self.audience_scope
      @audience_scope
    end
    
    def self.audiences=(audiences)
      @audiences = audiences
    end
    
    def self.audiences
      @audiences
    end    

    def self.required_claims=(required_claims)
      @required_claims = required_claims
    end
    
    def self.required_claims
      @required_claims
    end

    def self.identity_claim=(identity_claim)
      @identity_claim = identity_claim
    end
    
    def self.identity_claim
      @identity_claim
    end
    
  end
end    

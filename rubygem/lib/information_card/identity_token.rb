module InformationCard
  class IdentityToken
    attr_reader :errors, :claims
    
    def initialize
      @errors = {}
      @claims = {}
    end
    
    def valid?
      @errors.empty?
    end
    
    def unique_id
      nil
    end
    
    def ppid
      nil
    end 
  end 
end
      
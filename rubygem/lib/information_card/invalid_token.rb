module InformationCard
  class InvalidToken < IdentityToken
    def initialize(errors)
      super()
      @errors = errors
    end
  end
end
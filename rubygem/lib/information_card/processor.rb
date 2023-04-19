module InformationCard
  class Processor   
    def self.process(encrypted_information_card_xml)
      begin    
        decrypter = Decrypter.new(encrypted_information_card_xml, 
                                  InformationCard::Config.certificate_location, 
                                  InformationCard::Config.certificate_subject)
        decrypted_information_card = decrypter.decrypt
      rescue => e
        return InvalidToken.new({:decryption => e.message})
      end              
      SamlToken.create(decrypted_information_card)
    end
  end
end

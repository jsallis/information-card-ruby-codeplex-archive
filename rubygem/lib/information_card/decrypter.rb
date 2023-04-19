module InformationCard
  class Decrypter
    
    attr_reader :errors
                
    def initialize(encrypted_information_card_xml, certificate_location, certificate_subject)
      @xml_document = REXML::Document.new(encrypted_information_card_xml)
      @certificate_location = certificate_location
      @certificate_subject = certificate_subject
      @errors = {}      
    end
    
    def decrypt
      private_key = CertificateUtil.lookup_private_key(@certificate_location, @certificate_subject)      
      encrypted_data = REXML::XPath.first(@xml_document, "enc:EncryptedData", {"enc" => Namespaces::XENC})
      key_info = REXML::XPath.first(encrypted_data, "x:KeyInfo", {"x" => Namespaces::DS})   
      encrypted_key = REXML::XPath.first(key_info, "e:EncryptedKey", {"e" => Namespaces::XENC})
      key_cipher = REXML::XPath.first(encrypted_key, "e:CipherData/e:CipherValue", {"e" => Namespaces::XENC})
      key = decrypt_key(key_cipher.text, private_key)

      cipher_data = REXML::XPath.first(@xml_document, "enc:EncryptedData/enc:CipherData/enc:CipherValue", {"enc" => Namespaces::XENC})
      decrypt_cipher_data(key, cipher_data.text)
    end
    
    def valid?
      # TODO: Should perform more validation and handle errors more gracefully.
      #       ex. What if algorithm is not supported?
      errors.empty?
    end
    
    private 
    
    def decrypt_key(key_wrap_cipher, private_key, ssl_padding=OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
      # TODO: Encrypted method is assumed t obe rsa-oaep-mgf1p
      from_key = OpenSSL::PKey::RSA.new(private_key)
      key_wrap_str = Base64.decode64(key_wrap_cipher)
      from_key.private_decrypt(key_wrap_str, ssl_padding)        
    end
    
    def decrypt_cipher_data(key_cipher, cipher_data)
      cipher_data_str = Base64.decode64(cipher_data)      
      mcrypt_iv = cipher_data_str[0..15]
      cipher_data_str = cipher_data_str[16..-1]
      # TODO: Encryption method algorithm is assumed to be aes256-cbc.
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.decrypt
      cipher.key = key_cipher
      cipher.iv = mcrypt_iv  
      result = cipher.update(cipher_data_str)
      result << cipher.final
    end
  end
end
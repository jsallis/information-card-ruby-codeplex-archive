require 'openssl'

module InformationCard
  class CertificateUtil
      
    def self.lookup_private_key(directory, subject)
      path = File.join(directory, '*.crt')
      Dir[path].each do |cert_file|
        cert = OpenSSL::X509::Certificate.new(File.read(cert_file))
        return OpenSSL::PKey::RSA.new(File.read(cert_file.gsub(/.crt$/, '') + ".key")) if (cert.subject.to_s == subject)
      end
      raise "No private key found in #{path.gsub(/\*.crt/, '')} with subject #{subject}"
    end
  end
end



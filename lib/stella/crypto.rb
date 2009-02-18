require 'base64'  

if RUBY_PLATFORM !~ /java/
  require 'openssl'
else
  module JRuby #:nodoc:
     module OpenSSL #:nodoc:
       GEM_ONLY = false unless defined?(GEM_ONLY)
     end
   end
  
   if JRuby::OpenSSL::GEM_ONLY
     require 'jruby/openssl/gem'
   else
     module OpenSSL #:nodoc:all
       class OpenSSLError < StandardError; end
       # These require the gem
       %w[
       ASN1
       BN
       Cipher
       Config
       Netscape
       PKCS7
       PKey
       Random
       SSL
       X509
       ].each {|c| autoload c, "jruby/openssl/gem"}
     end
     require "jruby/openssl/builtin"
   end
end

# A small collection of helper methods for dealing with RSA keys. 
module Stella::Crypto
  VERSION = 1.0
  
  def self.create_keys(bits = 2048)
    pk = OpenSSL::PKey::RSA.new(bits)
  end
  
  @@digest = OpenSSL::Digest::Digest.new("sha1")
  def self.sign(secret, string)
    sig = OpenSSL::HMAC.hexdigest(@@digest, secret, string).strip
    #sig.gsub(/\+/, "%2b")
  end
  def self.aws_sign(secret, string)
    Base64.encode64(self.sign(secret, string)).strip
  end
  
  # A class which represents an RSA or DSA key. 
  class Key
    attr_reader :data, :key
    
    # Create an instance of Crypto::Key with the provided rsa or dsa 
    # public or private key data. 
    def initialize(data)
      @data = data 
      @public = (data =~ /^-----BEGIN (RSA|DSA) PRIVATE KEY-----$/).nil?
      @key = OpenSSL::PKey::RSA.new(@data)
    end  
    
    # Create an instance of Crypto::Key using a key file. 
    #   key = Crypto::Key.from_file('path/2/id_rsa')
    def self.from_file(filename)    
      self.new File.read( filename )
    end
    
    # Encrypt and base64 encode the given text.
    def encrypt(text)
      Base64.encode64(@key.send("#{type}_encrypt", text))
    end
    
    # Decrypt the given base64 encoded text. 
    def decrypt(text)
      @key.send("#{type}_decrypt", Base64.decode64(text))
    end
  
    def private?();  !@public; end
    def public?();  @public;  end 
    
    def type
      @public ? :public : :private
    end
  end
end


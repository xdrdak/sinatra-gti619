root = ::File.dirname(__FILE__)
require ::File.join(root,'app')
require "webrick"
require 'webrick/https'
require 'openssl'

CERT_PATH = './'

webrick_options = {
        :Port               => 8443,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
        :DocumentRoot       => "/ruby/htdocs",
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(File.join(CERT_PATH, "server.crt")).read),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(File.join(CERT_PATH, "server.key")).read),
        :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

server = ::Rack::Handler::WEBrick
trap(:INT) do
    server.shutdown
end
server.run(SST::SinatraWarden.new, webrick_options)

run SST::SinatraWarden.new


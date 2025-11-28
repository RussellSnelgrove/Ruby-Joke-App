require 'net/http'
require 'uri'
require 'json'

class JokesController < ApplicationController
  rescue_from JSON::ParserError, with: :handle_json_parser_error

  def index
    @jokes = Joke.recent
  end

  def new
    url = URI.parse('https://icanhazdadjoke.com/graphql')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    query = <<~GRAPHQL
      query {
          joke {
            joke
          }
        }
      GRAPHQL

      # Smart verification: only bypass CRL failures, reject other problems
    http.verify_callback = proc do |preverify_ok, ssl_context|
      if preverify_ok
          # Certificate passed all checks - accept it
          true
      else
          # Check what failed
          cert = ssl_context.current_cert
          error = ssl_context.error
          error_string = ssl_context.error_string

          logger.warn "SSL Verification issue: #{error_string} (code: #{error})"

          # Only accept if it's a CRL-related error
          # Error codes: 3 = unable to get CRL, 90 = CRL signature failure
      if error == 3 || error == 90
        logger.info "Bypassing CRL check failure for #{cert.subject}"
        true
          else
            # Reject other certificate problems (expired, wrong domain, etc.)
            logger.error "Certificate verification failed: #{error_string}"
            false
          end
        end
      end

    request = Net::HTTP::Post.new(url.path)
    request["Content-Type"] = "application/json"
    request.body = { query: query }.to_json

    
    response = http.request(request)

    result = JSON.parse(response.body).dig("data", "joke", "joke")
    @joke = Joke.new(joke: result)
    @joke.save
    redirect_to root_path
  end

  def handle_json_parser_error(exception)
    Rails.logger.error "JSON Parser Error: #{exception.message}"
    redirect_to jokes_path
  end
end

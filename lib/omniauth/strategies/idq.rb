require 'omniauth-oauth2'
require 'multi_json'

# Delegated Authorization Strategy for the OAuth2 client
module OAuth2
  module Strategy
    class DelegatedAuthorization < Base
      # The required query parameters for the authorize URL
      # is an exact copy of the same method in the AuthCode Strategy
      # @param [Hash] params additional query parameters
      def authorize_params(params = {})
        params.merge('response_type' => 'code', 'client_id' => @client.id)
      end

      # The authorization URL endpoint of the provider
      # Similar to the AuthCode Strategy, but in this case call
      # Client::delegated_authorization_url() to construct the authorization URL
      # @param [Hash] params additional query parameters for the URL
      def authorize_url(params = {})
        @client.delegated_authorization_url(authorize_params.merge(params))
      end
    end
  end
end

# Extend the OAuth2 Client with support for our Delegated Authorization Strategy
module OAuth2
  class Client
    # The authorize endpoint URL of the OAuth2 provider
    # we add support for generating a Delegated Authorization URL
    # @param [Hash] params additional query parameters
    def delegated_authorization_url(params = {})
      params = (params || {}).merge(redirection_params)
      connection.build_url(options[:delegated_authorization_url], params).to_s
    end

    # Creates a Delegated Authorization OAuth2 Strategy for the OAuth2 client
    def delegated_authorization
      @delegated_authorization ||= OAuth2::Strategy::DelegatedAuthorization.new(self)
    end
  end
end

# OmniAuth::Strategy for idQ extends the standard OmniAuth::OAuth2 Strategy
module OmniAuth
  module Strategies
    class Idq < OmniAuth::Strategies::OAuth2
      alias_method :request_phase_original, :request_phase
      # Provider Name
      option :name, 'idq'

      # Defaults can be overwritten upon initialization of the provider
      # in src/config/initializers/omniauth.rb
      option :client_options, {
        :site => "https://taas.idquanta.com",
        :token_url => "/idqoauth/api/v1/token",
        :authorize_url => "/idqoauth/api/v1/auth",
        :delegated_authorization_url => '/idqoauth/api/v1/pauth'
      }

      uid {
        raw_info['username']
      }

      info do
        {
          email: raw_info['email']
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      # Patched request_phase
      def request_phase
        # If a push_token was passed in, we want to carry out a delegated authorization
        if request.params['push_token']
          redirect client.delegated_authorization.authorize_url({:redirect_uri => callback_url}.merge(authorize_params))
        else
          # Otherwise proceed with the original omniauth-oauth2 request_phase
          request_phase_original
        end
      end

      # Allow push_token param through
      def authorize_params
        super.merge(push_token: request.params['push_token'], response_to: 'delegated_authorization')
      end

      # Need to patch the original callback_url method
      # the original puts all params from query_string onto the callback url
      # idQ does not support this behaviour. However, we need the Omniauth
      # feature to store k-v pairs from query string in the request.env['omniauth.params']
      # for handling delegated authorization requests in a stateless fashion.
      def callback_url
        full_host + script_name + callback_path
      end

      private

      # Our custom raw_info method which will make idQ user attributes accessible to Omniauth
      def raw_info
        @raw_info ||= MultiJson.decode(access_token.get('/idqoauth/api/v1/user').body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end

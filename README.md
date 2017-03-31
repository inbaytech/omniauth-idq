OmniAuth IdQ Strategy
==============

This gem contains the IdQ strategy for OmniAuth.

For more information about the idQ API: http://idquanta.com/

Usage
-------------

If you are using rails, you need to add the gem to your `Gemfile`:

    gem 'omniauth-idq'

You can pull in the gem directly from GitHub e.g.:

    gem "omniauth-idq", :git => "git://github.com/inbaytech/omniauth-idq.git"

The gem can be configured with your application specific OAuth2 settings via the  `config/initializers/omniauth.rb` initializer as follows:

```ruby
OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
   # Configure idQ OAuth2 Provider for OmniAuth
   provider :idq, 'client_id', 'client_secret', client_options: {}
end
```

Note: The file `config/initializers/omniauth.rb` may not exit on your system, please create it.

You can obtain your OAuth2 application credentials consisting of `client_id` and `client_secret`, from your account management console at https://idquanta.com.


## Authentication
After the gem is installed and configured, user authentication follows the standard OmniAuth procedure.
For the idQ provider, the authentication path is `/auth/idq`.

#### Example
If you are running a local Rails development server, your authentication URL will likely look like this:
	http://localhost:3000/auth/idq

#### Further Reading
More information on OmniAuth can be found at https://github.com/intridea/omniauth


Delegated Authorization
-----------------------
This module also supports idQ Delegated Authorization.

1. In the controller handling the business logic that requires Delegated Authorization, you first need to make a REST call to the idQ Trust as a Service backend to register your Delegated Authorization request.

2. Retrieve the `push_token` from the REST call response JSON.

3. Redirect the user into a standard OmniAuth flow, together with the `push_token` to trigger the Delegated Authorization logic. You can add additional parameters to the request if you need to remember application state, such as the action or context the Delegated Authorization was triggered in. These Parameters are stored in the OmniAuth `auth_params[]` hash and are available to your callback handler.

#### Example
The following is an example of an imagined `ItemController` that handles a `GET` request to a specific `item` resource by `id`. Before rendering the view associated with the requested `item`, we first kick off a Delegated Authorization request and wait for authorization approval.

```ruby
require 'rest-client'
class ItemController < ApplicationController
    # GET /item/:id
    def show
        # Find item in Database
        @item = Item.find(item_params[:id])

        # Payload to register Delegated Authorization Request
        payload = {
          title: "Authorize Access",
          message: "#{@current_user.name} is attempting to access #{@item.name}. Please approve or deny this access request.",
          target: @idQ_ID,
          client_id: ENV['IDQ_CLIENT_ID'],
          client_secret: ENV['IDQ_CLIENT_SECRET'],
          push_id: SecureRandom.uuid,
        }

        # URL to send REST request to
        url = ENV['IDQ_BASE_URL'] + ENV['IDQ_DA_REGISTER_PATH']

        # Send REST request to idQ Trust as a Service Backend
        begin
          response = RestClient.post url, payload, {content_type: "application/x-www-form-urlencoded"}

          # Retrieve response as JSON
          rjs = JSON.parse(response)

          # Obtain push token from response JSON
          pt = rjs['push_token']

          # Redirect the user into a standard OAuth2 flow
          redirect_to "/auth/idq?push_token=#{pt}&action=item_show&item_id=#{@item.id}" and return
        rescue
            flash[:danger] = "Error sending delegated authorization request!"
            render 'show' and return
        end
    end
end
```

The following is an implementation of an imagined callback handler that processes the answer to the Delegated Authorization request.  Since the callbacks for both Authentication and Authorization are the same under OmniAuth, the first step is to determine what type of callback is being handled (authentication or authorization).

``` ruby
class CallbackController < ApplicationController

   # General callback URL handler. Either handle Authentication, or Delegated Authorization.
   def handle_callback
      if is_authorization_response?
         handle_authorization
      else
         handle_authentication
      end
   end

   # Handler for Delegated Authorization Responses
   def handle_authorization
      # ItemController::show
      if auth_params['action'] == 'item_show'
         item_id = auth_params['item_id']
         @item = Item.find(item_id)
         if is_approved?(auth_hash)
            render 'show_item' and return
         else
            render 'access_denied' and return
         end
      end
   end

   protected

   # Helpers
   def is_approved?(auth_hash)
      response_code = auth_hash['extra']['raw_info']['response_code']
      return response_code == '1'
   end

   def is_authorization_response?
      if auth_hash['extra']['raw_info']['response_code']
         true
      else
         false
      end
   end

end
```

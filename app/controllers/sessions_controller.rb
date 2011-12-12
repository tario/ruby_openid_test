  class SessionsController < ApplicationController
    def create
      if using_open_id?("https://www.google.com/accounts/o8/id")
        open_id_authentication
      else
        failed_login "Sorry, only login with openid are accepted"
      end
    end
    
    def failed
      
    end

    def new
      redirect_to '/sessions/create'
    end

    protected
      def open_id_authentication
        authenticate_with_open_id("https://www.google.com/accounts/o8/id") do |result, identity_url|
          if result.successful?
            if @current_user = User.find_by_identity_url(identity_url)
              successful_login
            else
              failed_login "Sorry, no user by that identity URL exists (#{identity_url})"
            end
          else
            failed_login result.message
          end
        end
      end


    private
      def successful_login
        session[:user_id] = @current_user.id
        redirect_to(root_url)
      end

      def failed_login(message)
        flash[:error] = message
        redirect_to('/sessions/failed')
      end
  end
  
  class SessionsController < ApplicationController
    def create
      if using_open_id?("https://www.google.com/accounts/o8/id")
        open_id_authentication(:register_username => params[:register_username])
      else
        failed_login "Sorry, only login with openid are accepted"
      end
    end
    
    def welcome
    end
    
    def register
      @openid_email = params["openid_email"]
      @openid_first = params["openid_first"]
      @openid_last = params["openid_last"]
    end
    
    def failed
      
    end
    
    def destroy
      session[:google_signed_in] = false
      session[:user_id] = nil
      
      redirect_to(root_url)
    end

    def new
      redirect_to '/sessions/create'
    end

    protected
      def open_id_authentication(args)
        ax_attributes = ["http://axschema.org/contact/email","http://axschema.org/namePerson/last","http://axschema.org/namePerson/first"]
        authenticate_with_open_id("https://www.google.com/accounts/o8/id",
                    :required => ax_attributes
                    ) do |result, identity_url, registration|
          if result.successful?
            ax_response = OpenID::AX::FetchResponse.from_success_response(request.env[Rack::OpenID::RESPONSE])            
            
            session[:google_signed_in] = true
            @current_user = User.find_by_identity_url(identity_url)
            
            if @current_user
              successful_login
            else
              if ax_response
                openid_first = ax_response["http://axschema.org/namePerson/first"].first
                openid_last = ax_response["http://axschema.org/namePerson/last"].first
                openid_email = ax_response["http://axschema.org/contact/email"].first
              end 
              
              if args[:register_username]
                if User.find_by_username(args[:register_username])
                  failed_login "Cannot register a user named '#{args[:register_username]}', the user already exists in the database"
                else
                  @current_user = User.new(:identity_url => identity_url, :username => args[:register_username])
                  @current_user.save
                  successful_login
                end
              else
                if ax_response
                  redirect_to "/sessions/register?openid_first=#{openid_first}&openid_last=#{openid_last}&openid_email=#{openid_email}"
                else
                  redirect_to "/sessions/register"
                end
              end
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
  
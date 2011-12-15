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
      openid_data = session[:openid_data] || {}
      @openid_email = openid_data[:email]
      @openid_first = openid_data[:first]
      @openid_last = openid_data[:last]
    end
    
    def failed
      
    end
    
    def destroy
      session[:google_signed_in] = false
      session[:user_id] = nil
      session[:openid] = nil
      
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
                openid_email = ax_response["http://axschema.org/contact/email"].first
                session[:openid_data] = { :first => ax_response["http://axschema.org/namePerson/first"].first,
                                        :last => ax_response["http://axschema.org/namePerson/last"].first,
                                        :email => openid_email }
              else
                openid_email = args[:register_username]
              end 
              
              if openid_email
                if User.find_by_username(openid_email)
                  failed_login "Cannot register a user named '#{openid_email}', the user already exists in the database"
                else
                  @current_user = User.new(:identity_url => identity_url, :username => openid_email)
                  @current_user.save
                  successful_login
                end
              else
                redirect_to "/sessions/register"
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
  
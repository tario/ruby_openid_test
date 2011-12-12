  class SessionsController < ApplicationController
    def create
      if using_open_id?("https://www.google.com/accounts/o8/id")
        open_id_authentication(:register_username => params[:register_username])
      else
        failed_login "Sorry, only login with openid are accepted"
      end
    end
    
    def register
    end
    
    def failed
      
    end

    def new
      redirect_to '/sessions/create'
    end

    protected
      def open_id_authentication(args)
        authenticate_with_open_id("https://www.google.com/accounts/o8/id") do |result, identity_url|
          if result.successful?
            @current_user = User.find_by_identity_url(identity_url)
            
            if @current_user
              successful_login
            else
              if args[:register_username]
                if User.find_by_username(args[:register_username])
                  failed_login "Cannot register a user named '#{args[:register_username]}', the user already exists in the database"
                else
                  @current_user = User.new(:identity_url => identity_url, :username => args[:register_username])
                  @current_user.save
                  successful_login
                end
              else
                redirect_to '/sessions/register'
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
  
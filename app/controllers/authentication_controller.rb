# This authentication controller has a number of functions
# [#login]           Show the login view and login users
# [#create_admin]    Create the first user: admin
# [#forgot_password] Generate and mail a new password
# [#logout]          Logs out the current user (clears session)
class AuthenticationController < ApplicationController
  skip_before_filter :authorize

  # Display the login form and wait for user to enter a name and password.
  # We then validate these, adding the user object to the session if they authorize.
  def login
    if request.get?
      session[:user_id] = nil
    else
      # Try to get the user with the supplied username and password
      logged_in_user = User.login(params[:user][:name], params[:login][:password])

      # Create the session and redirect
      unless logged_in_user.blank?
        session[:user_id] = logged_in_user.id
        jumpto = session[:jumpto] || root_path
        session[:jumpto] = nil
        redirect_to(jumpto)
      else
        flash.now[:login_error] = 'Invalid username or password.'
      end
    end
  end

  def setup
    if User.immortal.exists?
      redirect_to :action => :login

    elsif request.post?
      @user = User.new_immortal params[:user]

      if @user.save
        reset_session
        session[:user_id] = @user.id

        GroupPermission.
            allow_crud Folder.make_root(@user), Group.create_administrators(@user)

        redirect_to root_path
      end
    end
  end

  # Generate/mail a new password for/to users who have forgotten it.
  def forgot_password
    if request.post?
      # Try to generate and mail a new password
      result = User.generate_and_mail_new_password(params[:user][:name], params[:user][:email])

      # Act according to the result
      if result['flash'] == 'forgotten_notice'
        flash.now[:forgotten_notice] = result['message']
      else
        flash[:login_confirmation] = result['message']
        redirect_to(:action => :login)
      end
    end
  end

  # Clear the current session and redirect to the login form.
  def logout
    reset_session
    @logged_in_user = nil
    redirect_to :action => :login
  end
end
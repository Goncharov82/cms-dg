class SessionsController < ApplicationController
  def new
    redirect_to admin_root_path if authenticated?
  end

  def create
    user = User.authenticate_by(email: params[:email].to_s.strip.downcase, password: params[:password])

    if user
      return_to = session.delete(:return_to_after_authenticating)
      reset_session
      session[:user_id] = user.id
      redirect_to return_to || admin_root_path,
        notice: "Вы вошли в систему."
    else
      flash.now[:alert] = "Неверный email или пароль."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Вы вышли из системы."
  end
end

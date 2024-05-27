class UsersController < ApplicationController


  # signup user using username, email and password
  def create
    user = User.create(user_params)
    if user.valid?
      session[:user_id] = user.id
      render json: { user: user, status: :created }
    else
      render json: { error: "Invalid username or password" }, status: :unprocessable_entity
    end
  end

  # login user using email and password
  def login
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      render json: { user: user, status: :ok }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def logout
    session.delete :user_id
    render json: { message: "Logged out" }, status: :ok
  end

  def is_user_logged_in
    if logged_in
      render json: { logged_in: true, user: current_user }, status: :ok
    else
      render json: { logged_in: false, message: "No such user" }, status: :unauthorized
    end
  end

  # fetch data from cat-fact api
  def fetch_data
    response = HTTParty.get('https://cat-fact.herokuapp.com/facts', verify: false)
    facts = response.parsed_response

    formatted_facts = facts.map do |fact|
      {
        id: fact['id'],
        fact: fact['text'],
        verified: fact['status']['verified'],
        created_on: DateTime.parse(fact['createdAt']).strftime('%d-%m-%Y %H:%M:%S')
      }
    end
    render json: formatted_facts
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end

  def authorized
    render json: { message: "Please log in" }, status: :unauthorized unless logged_in
  end

  def logged_in
    !!current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end

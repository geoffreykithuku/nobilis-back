class UsersController < ApplicationController

  before_action :authorize_user, except: [:create, :login]

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
      render json: { user: user, status: :ok}
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def logout
    session.delete :user_id
    render json: { message: "Logged out" }, status: :ok
  end


  def is_user_logged_in
    if @current_user
      render json: { logged_in: true, user: @current_user }
    else
      render json: { logged_in: false }
    end
  end


  # fetch data from cat-fact api
  def fetch_data
    response = HTTParty.get('https://cat-fact.herokuapp.com/facts')
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



  def authorize_user
    if session[:user_id]
      @current_user = User.find(session[:user_id])
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

end

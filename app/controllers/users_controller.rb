class UsersController < ApplicationController

  before_action :authorize_user, except: [:create, :login]

  # signup user using username, email and password
  def create
    user = User.create(user_params)
    if user.valid?
      payload = { user_id: user.id }
      token = encode_token(payload)
      render json: { user: user, token: token }, status: :created
    else
      render json: { error: "Invalid username or password" }, status: :unprocessable_entity
    end
  end


  # login user using email and password
  def login
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      payload = { user_id: user.id }
      token = encode_token(payload)
      render json: { user: user, token: token }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end


  def is_user_logged_in
    render json: { user: @current_user }, status: :ok
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
    params.require(:user).permit(:username, :email, :password)
  end

   def encode_token(payload)
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def decode_token(token)
    JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256')[0]
  end

  def authorize_user
    header = request.headers['Authorization']
    token = header.split(' ')[1] if header
    begin
      decoded_token = decode_token(token)
      @current_user = User.find(decoded_token['user_id'])
    rescue
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

end

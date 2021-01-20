class Api::SessionsController < ApplicationController

  def create
    user = User.find_by(email: session_params[:email])

    if user&.authenticate(session_params[:password])
      token = Jwt::TokenProvider.call(user_id: user.id)
      # NOTE: このuser_idというシンボルがJSON形式にした時にキーになる。
      render json: ActiveModelSerializers::SerializableResource.new(user, serializer: UserSerializer).as_json.deep_merge(user: { token: token })
      # NOTE: 引数によって動的にSerializerクラスやインスタンスを返却できる。
    else
      render json: { error: { messages: ['メールアドレスまたはパスワードに誤りがあります。'] } }, status: :unauthorized
    end
  end

  def destroy
    # TODO: ログアウト処理を後ほど実装
  end


  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end

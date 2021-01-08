class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  # NOTE: CSRF対策のメソッドで Rails内部からのリクエストに対してはセキュリティトークンなどを仕込んでくれる様になる。
  # そうする事で外部からの不正なリクエストを送信させるCSRFを防ぐことができる。
  # withオプションはトークンが一致しなかった場合にどうするかという事で今回はセッションを空にする。
  # QUESTION: with: :null_sessionはデフォルトだと記事に書いてあったんですけど明示的に書いているだけですか？
  class AuthenticationError < StandardError; end
  # NOTE: 独自例外を作成している。StandardErrorを継承することで例外を作成することが出来る。

  rescue_from ActiveRecord::RecordInvalid, with: :render_422
  rescue_from AuthenticationError, with: :not_authenticated

  def authenticate
    raise AuthenticationError unless current_user
  end

  def current_user
    @current_user ||= Jwt::UserAuthenticator.call(request.headers)
  end

  private

  def render_422(exception)
    render json: { error: { messages: exception.record.errors.full_messages } }, status: :unprocessable_entity
    # NOTE: バリデーションエラーの場合にunprocessable_entity（422）を返す。
  end

  def not_authenticated
    render json: { error: { messages: ['ログインしてください。'] } }
  end
end

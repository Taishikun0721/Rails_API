module Jwt::TokenProvider
  extend self
  # NOTE: 特異クラスを定義しているクラスメソッドと似た様な感じで呼び出せる。Jwt::TokenProvider.メソッド名みたいな感じ。

  def call(payload)
    issue_token(payload)
  end

  private

  def issue_token(payload)
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
    # NOTE: トークンを発行。署名アルゴリズムはデフォルトでHS256に指定されている。
  end
end
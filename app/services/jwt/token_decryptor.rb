module Jwt::TokenDecryptor
  extend self

  def call(token)
    decrypt(token)
  end

  private

  def decrypt(token)
    JWT.decode(token, Rails.application.credentials.secret_key_base)
  # NOTE: トークン発行・検証をする際に、鍵が必要になる。
  # これはバレてはいけない鍵なのでRailsの場合は、secret_key_baseを使用している。
  rescue StandardError
    raise InvalidTokenError
  end
end
class InvalidTokenError < StandardError; end
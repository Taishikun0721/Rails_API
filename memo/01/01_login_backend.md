# 01_ログイン機能バックエンド

## 初期設定

ここはRails特訓コースと一緒の様な進め形で実施しました。
デバッグ系のgemは指定はなかったけれど便利なので勝手に入れました


## Jwt認証とは

Jwt認証とはJSONに電子署名を加えた**token**の事をいう。
今回はユーザーからJsonでリクエストを受けたら、そこにサーバー側で電子署名を加えてtokenを生成する。それを認証Tokenとして使用する様に、ユーザーに返却する。

特徴としてはtokenはステートレスなのでセッションの様に毎回サーバー側で`redis`などにアクセスしてセッションidを使用して参照するという様な事はしない。
あくまで送信されてきたtokenが正しいかどうかを毎回確認している。(ここのイメージがちょっと怪しいです)

## Jwtの構成

このあたりの記事がわかりやすかった。

[攻撃して学ぶJWT【ハンズオンあり】](https://moneyforward.com/engineers_blog/2020/09/15/jwt/)
[JWTとは何か?(ruby-jwtのインストール)](https://blog.cloud-acct.com/posts/u-rails-whats-jwt/) 

まずJwtはピリオドで区切られた3つの部分に分かれている。
↓こんな感じ

```
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.cRSVkjWcS-38pQG8Ibuwy2ghh9Z6-Ohk5QdH0WkrLhk
                    ↑これ　　　　　　　　　↑これ　　　　　　　　　　　　　　　　　　
```
このサイトに貼り付けたらわかりやすかった。
[jwt.io](https://jwt.io/)

[![Image from Gyazo](https://i.gyazo.com/45b924c8341f354bd6e1aba363e5f5b2.png)](https://gyazo.com/45b924c8341f354bd6e1aba363e5f5b2)


するとこの様にデコードした結果が出てきました。
これは`Postman`でレスポンスとして返ってきたtokenを試したので
サーバー側ではリクエストとして送信した認証情報を元にtokenを生成していることがわかりました。


今回は`HS256`という方法でが使われていて(デフォルト)
これは**署名時につけた鍵と同じ鍵で検証する**という方法なので`secret_key_base`でエンコードしたものは`secret_key_base`でデコードしてます。鍵はもちろんバレてはいけないです。ただここがメリットでもあってトークンが流出しても鍵がなければデコードできないです。ただ流出していいかと言われたらはっきりといいと答える自信がないので詳しく調べたい。

下記の様に鍵を使ってエンコードとデコードをしてます。

エンコード

```
  def issue_token(payload)
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
```

デコード

```
  def decrypt(token)
    JWT.decode(token, Rails.application.credentials.secret_key_base)
  rescue StandardError
    raise InvalidTokenError
  end
```


`sessions_controller`

```
  def create
    user = User.find_by(email: session_params[:email])

    if user&.authenticate(session_params[:password])
      token = Jwt::TokenProvider.call(user_id: user.id)
      render json: ActiveModelSerializers::SerializableResource.new(user, serializer: UserSerializer).as_json.deep_merge(user: { token: token })
    else
      render json: { error: { messages: ['メールアドレスまたはパスワードに誤りがあります。'] } }, status: :unauthorized
    end
  end
```

`has_sequre_password`を使用しているので、`authenticate`メソッドで認証が成功したらトークンを発行したらトークンを生成する処理に移行してます。


`token_provider`

```
module Jwt::TokenProvider
  extend self

  def call(payload)
    issue_token(payload)
  end

  private

  def issue_token(payload)
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
end
```

最終的にはエンコードされた`token`がレスポンスとしてクライアントに返却されています。

■レスポンス

```
render json: ActiveModelSerializers::SerializableResource.new(user, serializer: UserSerializer).as_json.deep_merge(user: { token: token })
```

[![Image from Gyazo](https://i.gyazo.com/24bbe671244b71391021c4905ebaa003.png)](https://gyazo.com/24bbe671244b71391021c4905ebaa003)

これが初回ログイン時の動作になります。
２回目以降のログインはここで返却された`token`をリクエストの際に送信してサーバー側でデコードして検証するっていう流れになります。

## APIモードとは
MVCのVの部分がないモードの事。本来ならSRR(サーバーサイドレンダリング)を行う為に`erb`のファイルがあるが
`rails new`の時点でview関係のファイルとかgemが作成されない。
またデフォルトでレスポンスはJSONを返す使用になっている。（作った事ないけど笑）

## webpackerとは

Rails6.0から標準実装になったjavascriptのパッケージマネージャーのこと。
実際には`webpack`という仕組みをRailsで使いやすくすつためのラッパーが`webpacker`というらしい。

マニフェストファイルが`app/javascript/packs`いかに変更されて流ので`application_html.erb`の
記述も

```
    <%= javascript_pack_tag 'application' %>
```
に変更する必要がある。

## Postmanとは
簡単にリクエストを送信することができるツールの事。
curlとかでも同じことができるけどオプションとかが結構ややこしい。けどPostmanを使用すれば
簡単にリクエストを送信することができる。

## シリアライザとは

JSONなどのAPIで扱いやすい様に構造を変換することをシリアライズといい、プログラミングで使用する
オブジェクトの形にするのをデシリアライズという。

今回はActiveModel::Serializersを使用してJSONを返却している。

## まとめ（現状の認識）

jwt認証の流れ

1. 認証用のデータを送信する。 `クライアント`
2. エンコードしてトークンをレスポンスで返す `サーバー`
3. 初回ログイン終了
4. リクエストと共に初回ログイン時に受け取ったトークンを送信する `クライアント`
5. トークンがあっているかリクエストの度に検証する `サーバー`

実装してみて思った事
1. 認証とかセキュリティって難しい
2. moduleの使い方が勉強になった。
3. 例外処理は復習が必要
4. `ActiveModel:serializers`は意外とシンプルだった

## 質問
1. トークンはリクエストの時に毎回送信するんですか？ ステートレスだから毎リクエスト送信しないとログイン状態を維持できない？
2. 今回`services`ディレクトリを作成するのはサービスオブジェクトっていうデザインパターンですか？
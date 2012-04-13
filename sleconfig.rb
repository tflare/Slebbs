# $Id: mtconfig.rb 157 2005-10-02 13:01:18Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

module SleBbs

module Config
  class ConfigError < StandardError; end;

  root = File::dirname(__FILE__)

  MC_CONFIG = {
    # BBSのタイトル名称
    :bbsname => "SleBbs_test",

    # 新規のスレッド作成の許可: true false
    :new_thread => true,

    # スレッドの最大数
    :max_thread => 20,

    # ひとつのスレッドの最大レス数
    :max_res => 200,

    # 初期表示画面の表示するレス
    :start_display_res => "|5",

    # 名前とメールアドレスを覚えさせる: true false,
    :session => true,

    # スタイルシートパス
    :css_path => "./theme/basic/basic.css",

    # gzip圧縮転送 true false
    :gzip_transfer => false,

    # host名の表示, true false
    :host => true,

    # user_agentの表示, true false
    :ua => true,

    # 名前の入力がない時の表示内容
    :noname => "NOBODY",

    # データ削除時の表示内容
    :delete_display => "delete",

    # 1レスの本文の行数制限, falseで制限なし
    :res_max_line => 20,

    # バックアップの間隔 秒数で指定
    :backup_interval => 60 * 60 * 24 * 1, # 1 day

    # メンテナンスページを表示する。: true false
    :maintenance_mode => false,

    ###################################
    # 簡易認証用
    # パスワードは暗号化されています。
    # 画面の管理から更新を行ってください。

    # 認証を行う: true 認証を行わない:false
    :auth      => true,
    :auth_user => "test",
    :auth_pass => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",

    ###################################
    #以下については、通常変更する必要はありません。

    :bbspath => root,

    # 実行ファイルのパスを設定する。
    :indexpath => "index.cgi",
    :config_path => __FILE__,
    :dbpath => "#{root}/db",
    :dbextname => ".db",
    :templatepath => "#{root}/template",
  }

  # use Config[:bbsname]
  def self.[](key)
    unless MC_CONFIG.has_key?(key)
      raise ConfigError, "key not found: #{key}" 
    end
    MC_CONFIG[key]
  end

  def self.[]=(key, value)
    MC_CONFIG[key] = value
  end

end
end
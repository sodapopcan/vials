import Config

config :vial, user_home: fn -> System.user_home() end

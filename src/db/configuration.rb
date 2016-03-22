# coding: utf-8

require 'config/load_env'
require "active_record"

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.establish_connection(
  adapter:  "postgresql",
  host:     ENV['POSTGRES_HOST'] || 'localhost',
  database: "stockdb",
  port:     ENV['POSTGRES_PORT'] || 5432,
  username: ENV['POSTGRES_USER'] || 'postgres',
  password: ENV['POSTGRES_PASSWORD'] || 'mysecretpassword'
)

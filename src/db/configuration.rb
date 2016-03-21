require 'dotenv'
require "active_record"

Dotenv.load

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.establish_connection(
  adapter:  "postgresql",
  host:     ENV['POSTGRES_HOST'] || 'localhost',
  database: "stockdb",
  port:     ENV['POSTGRES_PORT'] || 5432,
  username: ENV['POSTGRES_USER'] || 'postgres',
  password: ENV['POSTGRES_PASSWORD'] || 'mysecretpassword'
)

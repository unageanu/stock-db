# coding: utf-8

require 'config/load_env'
require "active_record"

#ActiveRecord::Base.logger = Logger.new($stdout)
config = {
  adapter:  "postgresql",
  host:     ENV['POSTGRES_HOST'] || 'localhost',
  database: "stockdb",
  port:     ENV['POSTGRES_PORT'] || 5432,
  username: ENV['POSTGRES_USER'] || 'postgres',
  password: ENV['POSTGRES_PASSWORD'] || 'mysecretpassword'
}
begin
  ActiveRecord::Base.establish_connection(config)
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError
  ActiveRecord::Base.establish_connection(config.merge(database:'postgres'))
  ActiveRecord::Base.connection.create_database(config[:database])
  ActiveRecord::Base.establish_connection(config)
end

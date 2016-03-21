# -*- encoding: utf-8 -*-

require "db/configuration"
require "db/migrate/create_tables"
require "models/user"

User.create(
  :name     => "sasaki takeru",
  :nickname => "urekat",
  :profile  => "hehe hoho."
)

puts "User.count=#{User.count}"

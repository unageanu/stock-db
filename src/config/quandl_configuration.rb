# coding: utf-8

require 'quandl'
require 'config/load_env'

Quandl::ApiConfig.api_key     = ENV['QUANDL_API_KEY']
Quandl::ApiConfig.api_version = ENV['QUANDL_API_VERSION']

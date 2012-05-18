SQLITE3_DB_PATH    = File.expand_path('../../.db.sqlite3', __FILE__)
CONFIG_PATH        = File.expand_path('../../config.yml', __FILE__)

$:.push File.expand_path("..", __FILE__)
require 'bundler/setup'

require 'openssl'
# Hack to avoid verifying the SSL certificate
module OpenSSL::SSL
  remove_const :VERIFY_PEER
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'active_record'
require 'logger'
require 'ostruct'
require 'sqlite3'

require 'cimc/calendar'
require 'cimc/event'
require 'cimc/scraper'

Config = OpenStruct.new(YAML.load_file(CONFIG_PATH))
ENV["TZ"] = Config.cimc_timezone

ActiveRecord::Base.logger = Logger.new('/dev/null')
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => SQLITE3_DB_PATH)
CIMC::Event.create_table unless CIMC::Event.table_exists?

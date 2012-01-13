require 'active_record'
require 'digest/md5'

module CIMC
  class Event < ActiveRecord::Base

    validates_presence_of :title, :starts_at, :ends_at, :description, :event_hash, :gcal_status
    validates_presence_of :finishes_at, :if => lambda { |e| e.repeat_type }
    validates_inclusion_of :repeat_type, :in => %w( daily weekly ), :allow_nil => true
    validates_inclusion_of :gcal_status, :in => %w( to_add added to_remove )
    validates_uniqueness_of :event_hash
    
    EVENT_HASH_KEYS = %w(title starts_at ends_at repeat_type finishes_at description)
    EVENT_HASH_DELIMETER = '@@@'
    
    def create_hash
      values = EVENT_HASH_KEYS.map do |key|
        send(key).to_s
      end
      self.event_hash = Digest::MD5.hexdigest(values.join(EVENT_HASH_DELIMETER))
    end
    
    def self.build_from_scraped_data(data)
      event = self.new(
        :title       => data[:title],
        :starts_at   => Time.parse("#{data[:start_date]} #{data[:start_time]}"),
        :ends_at     => Time.parse("#{data[:start_date]} #{data[:end_time]}"),
        :description => data[:description],
        :gcal_status => 'to_add'
      )
      if data[:end_date]
        days = (data[:end_date] - data[:start_date]).to_i
        if days > 0
          event.repeat_type = 'daily'
          event.finishes_at = Time.parse("#{data[:end_date]} #{data[:end_time]}")
        end
        event.repeat_type = 'weekly' if days > 9
      end
      event.create_hash
      event
    end
    
    def self.create_table
      connection.create_table(:events) do |t|
        t.string   :title,       :null => false
        t.datetime :starts_at,   :null => false
        t.datetime :ends_at,     :null => false
        t.string   :repeat_type
        t.datetime :finishes_at
        t.text     :description, :null => false
        t.string   :event_hash,  :null => false
        t.string   :gcal_status, :null => false
        t.string   :gcal_id
        t.timestamps             :null => false
      end
      connection.add_index :events, :event_hash, :unique => true
    end
  
  end
end

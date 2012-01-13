require 'google/api_client'

module CIMC
  class Calendar
  
    def initialize
      @calendar_id = Config.google_calendar_id
      @client = Google::APIClient.new
      @client.authorization.client_id     = Config.google_oauth["client_id"]
      @client.authorization.client_secret = Config.google_oauth["client_secret"]
      @client.authorization.scope         = Config.google_oauth["scope"]
      @client.authorization.refresh_token = Config.google_oauth["refresh_token"]
      @client.authorization.access_token  = Config.google_oauth["access_token"]
      if @client.authorization.refresh_token && @client.authorization.expired?
        @client.authorization.fetch_access_token!
      end
      @service = @client.discovered_api('calendar', 'v3')
    end
  
    def events
      result = []
      page_token = nil
      while true
        parameters = { 'calendarId' => @calendar_id }
        parameters['pageToken'] = page_token if page_token
        r = @client.execute(:api_method => @service.events.list, :parameters => parameters)
        r.data.items.each { |e| result << e }
        page_token = r.data.next_page_token
        return result unless page_token
      end
    end
    
    def add(event)
      body = {
        'summary' => event.title,
        'location' => Config.cimc_address,
        'description' => event.description,
        'start' => {
          'dateTime' => event.starts_at.xmlschema,
          'timeZone' => Config.cimc_timezone,
        },
        'end' => {
          'dateTime' => event.ends_at.xmlschema,
          'timeZone' => Config.cimc_timezone,
        },
      }
      if event.repeat_type
        last_time = event.finishes_at.utc.xmlschema.gsub(/[-:]/,'')
        body['recurrence'] = [
          "RRULE:FREQ=#{event.repeat_type.upcase};UNTIL=#{last_time}"
        ]
      end
      result = @client.execute(
        :api_method => @service.events.insert,
        :parameters => { 'calendarId' => @calendar_id },
        :body       => [ JSON.dump(body) ],
        :headers    => { 'Content-Type' => 'application/json' }
      )
      result.data.id
    end
    
    def delete(id)
      @client.execute(:api_method => @service.events.delete,
                      :parameters => {'calendarId' => @calendar_id, 'eventId' => id})
    end
    
        # 
        # result.data.items.each { |e|
        #   print e.summary.to_s + "\n"
        # end

  end
end

require 'mechanize'

module CIMC
  class Scraper
  
    def self.events
      self.new(Config.cimc_scheduler_url).events
    end
  
    def initialize(url)
      @date       = Date.today
      @url        = url
      @agent      = Mechanize.new
      set_sub_url
    end
    
    def tab_ids
      page = @agent.get(@sub_url)
      page.search('table#tab-table td.tabenroll').map do |td|
        value = td.attributes['onclick'].value.to_s
        value.match(%r!/asp/main_enroll.asp.+tabID=(\d+)!) ? $1.to_i : nil
      end.compact.sort
    end
  
    def events
      tab_ids.map do |tab_id|
        page = @agent.get "#{@sub_url}?date=#{@date.month}%2F#{@date.day}%2F#{@date.year}&tabID=#{tab_id}"
        page.search('table#cm-m-enroll-tbl table.mainText .mainText').map do |main|
          header = main.css('.mainTextBig > span')[0]
          next unless header
          dates = date_cleanup(main.css('.dates-and-time .dateSpan')[0].content)
          times = date_cleanup(main.css('.dates-and-time .times')[0].content)
          start_date, end_date = dates.split(' - ').map do |str|
            month, day, year = str.split('/').map(&:to_i)
            Date.new(year, month, day)
          end
          start_time, end_time = times.split(' - ')
          {
            :title       => cleanup(header.content),
            :start_date  => start_date,
            :end_date    => end_date,
            :start_time  => start_time,
            :end_time    => end_time,
            :description => cleanup(main.css('.description')[0].content),
          }
        end
      end.flatten.compact
    end
  
  protected

    def set_sub_url
      page = @agent.get(@url)
      form = page.form('wsLaunch')
      page = @agent.submit(form)
      @sub_url = page.uri.to_s.sub(/[^\/]+$/, page.frames[0].href.sub(/\?.*$/, ''))
    end

    def cleanup(s)
      s.gsub("\r", '').
        delete("^\u{0000}-\u{007F}").
        gsub(/\n +/, "\n").
        gsub(/ +\n/, "\n").
        gsub(/ +/, ' ').
        gsub(/\n{3,}/, "\n\n").
        strip
    end
  
    def date_cleanup(s)
      cleanup s.sub(/(From|Date):/, '')
    end

  end
end

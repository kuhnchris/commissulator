namespace :calendars do
  desc 'find newly created events and add them to the corresponding Follow Up Boss calendar'
  task :google_to_fub => :environment do
    calendar_driver = FubCalendarEvent.new
    Agent.find_each do |agent|
      if agent.google_calendar_id.present?
        calendar_driver.agent = agent
        local_events = []
        google_calendar = CalendarEvent.google_calendar agent
        google_calendar.events.each do |event|
          if CalendarEvent.where(:google_id => event.id).present?
            puts "We already have the event #{event.title}."
          else
            local_event = CalendarEvent.create_from_google(event, agent)
            local_event.agent = agent
            local_event.save
            local_events << local_event
          end
        end
        if local_events.present?
          # I wonder if I can just go from cookie to cookie without logging out
          calendar_driver.load_cookie
          calendar_driver.access_calendar_page
          
          local_events.each do |event|
            if event.invitees.present?
              guests = JSON.parse(event.invitees).map do |invitee|
                invitee.match(URI::MailTo::EMAIL_REGEXP).present? ? FubClient::Person.where(:email => invitee).fetch.first&.name : invitee
              end
            else
              guests = []
            end
            
            calendar_driver.access_event_input_form
            calendar_driver.add_event event, guests
          end
        end
      end
    end
  end
  
  desc 'find newly created events and add them to the corresponding Google calendar'
  task :fub_to_google => :environment do
    calendar_driver = FubCalendarEvent.new
    Agent.where(:id => 55).find_each do |agent|
      calendar_driver.agent = agent
      calendar_driver.load_cookie
      calendar_driver.access_calendar_page
      local_events = []
      
      calendar_driver.events.each do |event|
        code = calendar_driver.event_code event
        if CalendarEvent.where(:follow_up_boss_id => code).present?
          puts "We already have the event #{code}."
        else
          local_events << calendar_driver.scrape_event(event)
        end
      end
      
      local_events.each &:push_to_google
    end
  end
end

class CalendarEvent < ApplicationRecord
  extend Memoist
  
  belongs_to :agent, :optional => true
  
  def push_to_google
    CalendarEvent.google_calendar(agent).create_event do |e|
      e.attendees = invitee_emails.map { |invitee| {:email => invitee} }
      e.title = title
      e.description = description
      e.location = location
      e.start_time = start_time
      e.end_time = end_time
    end
  end
  
  def invitee_emails
    emails = invitees.map do |invitee|
      FubClient::Person.where(:first_name => invitee.split.first, :last_name => invitee.split.last).fetch.first&.emails&.first
    end
    emails << agent.email
    emails.compact
  end
  
  def CalendarEvent.create_from_google event, agent
    calendar_event = new
    calendar_event.title = event.title
    calendar_event.description = event.description
    calendar_event.location = event.location
    calendar_event.start_time = DateTime.parse event.start_time
    calendar_event.end_time = DateTime.parse event.end_time
    calendar_event.invitees = event.attendees
    calendar_event.google_id = event.id
    calendar_event.agent = agent
    calendar_event.save
    calendar_event
  end
  
  def CalendarEvent.find_or_create_from_google event, agent
    create_from_google event, agent unless CalendarEvent.where(:google_id => event.id).present?
  end
  
  def push_to_follow_up_boss
    fub_calendar_event = FubCalendarEvent.new
    fub_calendar_event.agent = agent
    fub_calendar_event.load_cookie
    fub_calendar_event.access_calendar_page
    fub_calendar_event.access_event_input_form
    guest_names = invitees.map do |invitee|
      FubClient::Person.where(:email => invitee['email']).fetch.first&.name
    end
    fub_calendar_event.add_event self, guest_names
  end
  
  def CalendarEvent.google_calendar agent
    Google::Calendar.new({:calendar => agent.google_calendar_id}, google_connection(agent.google_tokens['refresh_token']))
  end
  
  def CalendarEvent.google_connection token
    if Rails.env.production?
      Google::Connection.factory(
        :client_id => Rails.application.credentials.google[:client_id],
        :client_secret => Rails.application.credentials.google[:client_secret],
        :refresh_token => token,
        :redirect_url  => url_helpers.avatar_google_oauth2_omniauth_callback_url
      )
    else
      Google::Connection.factory(
        :client_id => Rails.application.credentials.google[:staging_client_id],
        :client_secret => Rails.application.credentials.google[:staging_client_secret],
        :refresh_token => token,
        :redirect_url  => url_helpers.avatar_google_oauth2_omniauth_callback_url
      )
    end
  end
  
  def microsoft_calendar
    microsoft_connection.get_events Agent.find(31).cookies.last.download
  end
  
  def microsoft_connection
    RubyOutlook::Client.new
  end
end

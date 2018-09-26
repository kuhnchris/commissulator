class Landlord < ApplicationRecord
  has_many :commissions
  has_many :leases
  
  def recent_commission
    commissions.order('approval_date desc nulls last').first
  end
  
  def fub_create
    first_name = name.split.first
    last_name = name.split[1..-1]&.join ' '
    similar_people = FubClient::Person.where(:firstName => first_name, :lastName => last_name).fetch
    person = similar_people.first if similar_people.present?
    person ||= FubClient::Person.new :firstName => first_name, :lastName => last_name
    person.emails = [{:value => email}] if email.present?
    person.phones = [{:value => phone_number, :type => 'work'}] if phone_number.present?
    person.tags = ['Landlord']
    begin
      person.save
    rescue NoMethodError => error
      Rails.logger.debug error.inspect
    end
    update_attribute :follow_up_boss_id, person.id
    person
  end
  
  def fub_person
    FubClient::Person.find(follow_up_boss_id) || fub_create
  end
end

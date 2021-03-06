class Email < ApplicationRecord
  belongs_to :client, :optional => true
  belongs_to :employer, :optional => true
  validates :address, :presence => true
  
  VARIETIES = ['home', 'school', 'work', 'office']
  
  def name
    address
  end
end

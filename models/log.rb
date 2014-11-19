class Log
  include DataMapper::Resource
  # properties
  property :id, Serial
  property :related_user, String
  property :message, String
  property :timestamp, DateTime

  before :create, :generate_timestamp


  def generate_timestamp
    self.timestamp = DateTime.now
  end


end

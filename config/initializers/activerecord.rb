module Pingalingaling
  def ping
    self.updated_at = Time.now.utc
  end

  def ping!
    ping
    save!
  end
end

ActiveRecord::Base.send(:include, Pingalingaling)

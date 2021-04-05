module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :client_id

    def connect
      self.client_id = request.params[:client_id]
    end
  end
end

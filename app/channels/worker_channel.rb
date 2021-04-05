class WorkerChannel < ApplicationCable::Channel
  def subscribed
    stream_for "client_#{client_id}"
  end

  def unsubscribed
    stop_all_streams
  end
end

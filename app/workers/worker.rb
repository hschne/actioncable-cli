class Worker
  include Sidekiq::Worker

  def perform(client_id)
    steps = 5
    WorkerChannel.broadcast_to("client_#{client_id}", type: :worker_started, total: steps)
    (1..steps).each do |progress|
      sleep(rand(1..3))
      Sidekiq.logger.info("Step #{progress} for client #{client_id}")
      WorkerChannel.broadcast_to("client_#{client_id}", type: :worker_progress, progress: progress)
    end
    WorkerChannel.broadcast_to("client_#{client_id}", type: :worker_done)
  end
end

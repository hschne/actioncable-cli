require 'thor'
require 'securerandom'
require 'net/http'
require 'async'
require 'async/io/stream'
require 'async/http/endpoint'
require 'async/websocket/client'
require 'ruby-progressbar'

class Worker < Thor
  include Thor::Actions

  desc 'start', 'Start a worker process'

  def start
    @client_id = SecureRandom.uuid
    url = "ws://localhost:3000/cable?client_id=#{@client_id}"
    Async do |_|
      endpoint = Async::HTTP::Endpoint.parse(url)
      Async::WebSocket::Client.connect(endpoint) do |connection|
        while (message = connection.read)
          on_receive(connection, message)
        end
      end
    end
  end

  private

  def on_receive(connection, message)
    if message[:type]
      handle_connection_message(connection, message)
    else
      handle_channel_message(connection, message)
    end
  end

  def handle_connection_message(connection, message)
    type = message[:type]
    case type
    when 'welcome'
      on_connected(connection)
    when 'confirm_subscription'
      on_subscribed
    end
  end

  def handle_channel_message(connection, message)
    message = message[:message]
    type = message[:type]
    case type
    when 'worker_started'
      total = message[:total]
      @bar = ProgressBar.create(title: 'Worker Progress', total: total, format: '%t %B %c/%C %P%%')
    when 'worker_progress'
      @bar.increment
    when 'worker_done'
      connection.close
    end
  end

  def on_connected(connection)
    content = { command: 'subscribe', identifier: { channel: 'WorkerChannel' }.to_json }
    connection.write(content)
    connection.flush
  end

  def on_subscribed
    Net::HTTP.start('localhost', 3000) do |http|
      http.get("/workers/start?client_id=#{@client_id}")
    end
  end
end

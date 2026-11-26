
require_relative "webhook_worker"

module Webhooks
  class WebhookWorkerRunner
    def initialize(worker: WebhookWorker.new, poll_interval: 2)
      @worker = worker
      @poll_interval = poll_interval
      @running = false
    end

    def run
      @running = true

      puts "[WebhookRunner] Started"

      while @running
        begin
          processed = @worker.perform_once

          sleep(@poll_interval) unless processed
        rescue StandardError => e
          warn "[WebhookRunner] Error: #{e.class} - #{e.message}"
          sleep(@poll_interval)
        end
      end

      puts "[WebhookRunner] Stopped"
    end

    def stop
      @running = false
    end
  end
end

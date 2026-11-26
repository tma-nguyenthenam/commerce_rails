
require "logger"

class RequestLogger
  def initialize(app)
    @app = app
    @logger = Logger.new($stdout)
  end

  def call(env)
    puts ">>> RequestLogger is running!"
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    status, headers, body = @app.call(env)

    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

    @logger.info(
      "#{env['REQUEST_METHOD']} #{env['PATH_INFO']} " \
      "status=#{status} duration=#{(duration * 1000).round(2)}ms"
    )

    [status, headers, body]
  rescue StandardError => e
    @logger.error(
      "#{env['REQUEST_METHOD']} #{env['PATH_INFO']} " \
      "error=#{e.class}: #{e.message}"
    )

    raise
  end
end

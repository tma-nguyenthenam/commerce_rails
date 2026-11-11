#!/usr/bin/env ruby
# Load test tối giản bằng Ruby thuần (không cần cài ab/wrk).
#
#   ruby script/load_test.rb http://localhost:3000/benchmark/io 10 100
#                            └ URL                              │  └ tổng số request
#                                                               └ số client chạy song song
require "net/http"
require "uri"

url, concurrency, total = ARGV
abort "Cách dùng: ruby script/load_test.rb URL [concurrency=10] [total=100]" unless url
concurrency = (concurrency || 10).to_i
total = (total || 100).to_i
uri = URI(url)

queue = Queue.new
total.times { queue << 1 }
latencies = Queue.new
errors = Queue.new

started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
workers = Array.new(concurrency) do
  Thread.new do
    until queue.empty?
      begin
        queue.pop(true)
      rescue ThreadError
        break
      end
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        res = Net::HTTP.get_response(uri)
        res.code == "200" ? latencies << (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) : errors << res.code
      rescue StandardError => e
        errors << e.class.name
      end
    end
  end
end
workers.each(&:join)
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

lat = Array.new(latencies.size) { latencies.pop }.sort
p95 = lat[(lat.size * 0.95).ceil - 1] || 0
puts format("%-40s concurrency=%-3d ok=%-4d err=%-3d  %.1f req/s  p50=%.0fms  p95=%.0fms",
            url, concurrency, lat.size, errors.size, lat.size / elapsed,
            (lat[lat.size / 2] || 0) * 1000, p95 * 1000)

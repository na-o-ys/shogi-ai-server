require 'open3'
require 'timeout'
require './store'
require './config'

Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'ai_worker', :size => 5 }
end

Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'ai_worker' }
end

class AIWorker
  include Sidekiq::Worker
  GIKOU_COMMAND = Config.get["gikou_command"]

  def perform(id, usi_seq, timeout_sec)
    @store = Store.new
    clear_result(id)
    exec_ai(id, usi_seq, timeout_sec)
  end

  def exec_ai(id, usi_seq, timeout_sec)
    Open3.popen3(GIKOU_COMMAND) do |stdin, stdout, _, thr|
      begin
        Timeout.timeout(timeout_sec + 5) do
          stdin.puts(usi_seq)
          stdin.flush
          while line = stdout.gets&.chomp
            append_result(id, line)
          end
        end
      rescue Timeout::Error
        # TODO: 子プロセスがゾンビ化する
        stdin.puts("quit")
        stdin.flush
        # Process.kill("KILL", thr.pid)
      end
    end
  end

  def clear_result(id)
    @store.set(id, nil)
  end

  def append_result(id, line)
    # TODO: synchronized
    @store.set(
      id, 
      [@store.get(id), line].map { |l|
        l.empty? ? nil : l
      }.compact.join("\n")
    )
  end
end

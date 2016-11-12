require 'json'
require './config'

class Store
  def initialize
    @redis = Redis.new(host: Config.get["redis"]["host"], port: Config.get["redis"]["port"])
  end

  def set(id, value)
    @redis.set(key(id), value)
  end

  def get(id)
    @redis.get(key(id))
  end

  def key(id)
    { id: id, key: "gikou_result" }.to_json
  end
end

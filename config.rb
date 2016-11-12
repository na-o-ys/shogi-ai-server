require 'yaml'

class Config
  def self.get
    YAML.load(open('./config.yml'))
  end
end

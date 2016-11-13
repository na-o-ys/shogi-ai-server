require 'digest/sha1'
require './worker'
require './store'

def usi_sequence(sfen, moves, time, multi)
  initial_position = sfen ? "sfen #{sfen}" : "startpos"
  position = "position #{initial_position} moves #{moves}"

<<"EOS"
usi
setoption name USI_Ponder value false
setoption name USI_Hash value 256
setoption name MultiPV value #{multi}
isready
usinewgame
#{position}
go btime 0 wtime 0 byoyomi #{time}
EOS
end

def exec_ai(usi_seq, timeout_sec)
  id = Digest::SHA1.hexdigest(usi_seq)
  AIWorker.perform_async(id, usi_seq, timeout_sec)
  id
end

get '/' do
  headers 'Access-Control-Allow-Origin' => '*'
  sfen  = params['sfen']
  moves = params['moves']
  time  = (params['time_sec'] || '10') + '000'
  multi = params['multi_pv'] || '1'

  seq = usi_sequence(sfen, moves, time, multi)
  exec_ai(seq, time.to_i / 1000)
end

get '/results/:id' do |id|
  headers 'Access-Control-Allow-Origin' => '*'
  Store.new.get(id)
end

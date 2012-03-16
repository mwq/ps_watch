require 'zk'
require 'rack'
require 'json'

class Host
  attr_reader :hostname, :pids, :proctable, :zk
  def initialize(hostname,zk)
    @hostname = hostname
    @proctable = {}
    @zk = zk

    node_subscription = zk.event_handler.register("/processes/#{hostname}") do |event|
      update_pids
    end

    @pids = []
    update_pids
    puts @pids
  end

  def update_pids
    pids = zk.children("/processes/#{hostname}", :watch => true)
    removed_pids =  @pids - pids
    created_pids =  pids - @pids

    created_pids.each do |pid|
      @proctable[pid] = cmdline(pid)
      puts "process created: #{pid}@#{hostname}"
      puts @proctable[pid] 
    end

    removed_pids.each do |pid|
      cmdline =  @proctable[pid] 
      puts "process stopped: #{pid}@#{hostname}"
      puts cmdline
      @proctable.delete pid
    end

    @pids = pids
  end

  def cmdline pid
    if zk.exists? "/processes/#{hostname}/#{pid}"
      cmdline = zk.get("/processes/#{hostname}/#{pid}").first
      cmdline ?  cmdline.gsub("\x00",' ') : nil
    end
  end
end

class Watcher
  def initialize
    puts 'initalizing'
    node_subscription = zk.event_handler.register("/processes") do |event|
      update_hosts
    end
    @hosts = []
    update_hosts
  end

  def update_hosts
    zk.children('/processes', :watch => true).each do |hostname|
      unless @hosts.map(&:hostname).include? hostname
        puts "found new host: #{hostname}"
        @hosts << Host.new(hostname,zk)
      end
    end
  end

  def new_connection
    zk_hosts = File.readlines('./config/zookeeper.conf').map(&:strip).join(',')
    @zk = ZK.new(zk_hosts)
  end
  
  def proctable
    @hosts.reduce({}){|pt, host|
      pt[host.hostname] = host.proctable
      pt
    }
  end

  def zk
    @zk ||= new_connection
  end

  def call(env)
     [200, {"Content-Type" => "application/json"}, [JSON.pretty_generate(proctable)]]
  end
end



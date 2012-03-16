# ps_watch

Keep track of your processes!

An daemon that sends a list of running processes to Zookeeper.

A web interface that shows all processes for all your servers.

## Usage
### agent
The agent is in bin/ps_watcher and should probably be put in your path.

copy config/zookeeper.conf.example to /etc/zookeeper.conf

start the agent with ```ps_watcher start```

### server/watcher

Copy the directory to some nice place

copy config/zookeeper.conf.example to config/zookeeper.conf

run ```rackup``` (or use some other rackisch server)

The startup will take a while if you have many servers with the agent on, but after the server has started updates should be nearly instant.

```curl localhost:9292``` will give you a nice json blob with all the processes on all systems.



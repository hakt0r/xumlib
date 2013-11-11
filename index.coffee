###

  xumlib - shell and network utility library
  
  c) 2012-2013 Sebastian Glaser <anx@ulzq.de>

  This file is part of the xumlib project.

  xumlib is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2, or (at your option)
  any later version.

  xumlib is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this software; see the file COPYING.  If not, write to
  the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
  Boston, MA 02111-1307 USA

  http://www.gnu.org/licenses/gpl.html

###

cp       = require 'child_process'
net      = require 'net'
util     = require 'util'

__env = process.env
__env.LANG = 'C'

module.exports = Lib = 

  sh : (cmd,args,callback) ->
    c = cp.spawn cmd, args, {encoding:'utf8'}
    c.on 'exit', callback

  script : (cmd, callback) ->
    c = cp.spawn "sh", ["-c",cmd]
    c.stdout.setEncoding 'utf8'
    c.stderr.setEncoding 'utf8'
    if callback?
      c.buf = []
      c.stdout.on 'data', (d) -> c.buf.push(d)
      c.stderr.on 'data', (d) -> c.buf.push(d)
      c.on 'close', (e) -> callback(e, c.buf.join().trim())
    else
      c.stdout.on 'data', (d) -> console.log d
      c.stderr.on 'data', (d) -> console.log d
    return c

  scriptline : (cmd, callback) ->
    c = cp.spawn "sh", [ "-c", cmd ], stdio : 'pipe'
    c.stdout.setEncoding 'utf8'
    c.stderr.setEncoding 'utf8'
    callback.error = console.log unless callback.error
    callback.line  = console.log unless callback.line
    callback.end   = (->) unless callback.end
    c.stderr.on 'data', (data) -> callback.error l.trim() for l in data.split '\n'
    c.stdout.on 'data', (data) -> callback.line  l.trim() for l in data.split '\n'
    c.on 'close', callback.end
    return c

  waitproc : (opts={}) ->
    start = Date.now()/1000 # util.print "wait ".yellow + " for ".white + opts.name + ' '
    wait = setInterval ( ->
      Lib.running opts.name, (e) ->
        unless e
          clearInterval wait
          opts.done true
        else
          clearInterval wait
          opts.done false if Date.now() / 1000 - start > opts.timeout
          util.print "."
    ), 250

  running : (name, callback) ->
    Lib.script "busybox ps -o comm | grep '^#{name}'", callback

  killall : (name, callback, fail) -> # util.print "kill".yellow + ' ' + name + ' '
    Lib.sh "busybox",["killall","-9",name], (e) ->
      Lib.running name, (e) ->
        unless e # console.log  "failed".green
          fail() if fail?
        else # console.log  "done".green
          callback() if callback?

  forkdm : (args,callback) -> 
    cmd = args.shift()
    cp.spawn cmd, args, detached : yes
    Lib.waitproc name : cmd, timeout : 5, done : callback

  readproc : (opts) ->
    { cmd, args } = opts
    handler = {}
    for t in ['exit','err','out','error'] when opts[t]?
      handler[t] = opts[t]; delete opts[t]
    if opts.script?
      s = opts.script; delete opts['script']
      cmd = 'sh'; args = ['-c',s]
    if opts.sudo?
      s = opts.sudo; delete opts['sudo']
      p = sudo [cmd].concat(args), cachePassword : yes, spawnOptions : env : __env
    else p = cp.spawn cmd, args, env : __env
    for t in ['out','err'] when handler[t]?
      p['std'+t].setEncoding 'utf8'
      p['std'+t].on 'data', handler[t]
    if handler.error?
      error = false; _err = (e) -> error = yes; handler.error e
      p.on 'error', _err; p.stderr.on 'data', _err
      p.on 'exit', (status) -> handler.exit(status) unless error
    else if handler.exit? then p.on 'exit', handler.exit
    return p

  send : (msg,callback) ->
    if msg? and typeof msg is "object"
      ondone = msg.done if msg.done?
      onerror = msg.error if msg.error?
    if typeof callback is "function" then ondone = callback
    ondone  = (->) unless ondone?
    onerror = (->) unless onerror?
    msg = JSON.stringify msg
    client = net.connect {port: 8124}, -> client.write msg
    client.on 'data', (data) ->
      client.end()
      ondone(data)
    client.on 'error', onerror

  getmac : (l) ->
    r = l.match /[0-9a-fA-F:]+:[0-9a-fA-F:]+:[0-9a-fA-F:]+:[0-9a-fA-F:]+:[0-9a-fA-F:]+:[0-9a-fA-F:]+/
    return if r then r.shift() else "00:00:00:00:00:00"

  ip2long : (ip) ->
    [o1,o2,o3,o4] = ip.split '.'
    return parseInt(o1) << 24 | parseInt(o2) << 16 | parseInt(o3) << 8 | parseInt(o4)

  long2ip : (ip) ->
    return [ip >>> 24, ip >>> 16 & 0xFF, ip >>> 8 & 0xFF, ip & 0xFF].join('.')

  dotmask2cidr : (mask) -> # courtsey of php.net manual (joe at joeceresini dot com)
    long = ip2long mask
    base = ip2long '255.255.255.255'
    return (32 - Math.log((long ^ base)+1,2)).toString().trim()

  cidr2dotmask : (cidr) -> # courtsey of m (hakt0r.de/om/, anx at hakt0r dot de)
    mask = 0xffffffff << 32 - cidr
    return ''+
      (mask >> 24 & 255)  +'+'+
      (mask >> 16 & 255 ) +'+'+
      (mask >> 8  & 255 ) +'+'+
      (mask & 255 )

  guess_ip_fromnet : (net, callback) ->
    return false unless net.indexOf '/' > -1
    cp.exec "ip addr show|tr / ' '|grep inet|grep -v inet6|awk '{print $2}'",{},(e,s,m) ->
      ips = s.split "\n"
      for addr in ips
        [ ip, mask ] = addr.split '/'
        mask = 0xffffffff << (32-mask)
        if ( ip2long(addr) & mask ) is ( ip2long($ip) & mask )
          console.log "guess ip".yellow, net, addr, (if net.indexOf('/') > -1 then "net" else "ptp")
          callback addr
    return true

  guess_net : (ip, callback) -> #roughly guess the network :> IMPROVE FIXME
    for i in [0...3]
      ip = ip.split '.'
      ip = ip.join '.'
      cp.exec """ip route show|grep "src #{ip}"|awk '{print $1}'|head -n1""",{},(e,s,m) ->
        s = s.trim()
        console.log "guess_net".yellow, ip.green, s.yellow
        callback ( if s.length > 0 then s else false )
    return true

  guess_dev : (ip, callback) ->
    cp.exec "ifconfig |grep -B1 #{ip}|head -n1|awk '{print $1}'",{},(e,s,m) ->
      s = s.trim()
      console.log "guess_dev".yellow, ip.green, s.yellow
      callback s

  guess_gw : (dev) ->
    return dev unless dev.ip? and dev.mask?
    oldgw  = @old.gw
    dev.gw = long2ip(ip2long(dev.ip) & ip2long(dev.mask) | ip2long('0.0.0.1'))
    console.log "guess".yellow, dev.dev.green, dev.gw.red
    return dev
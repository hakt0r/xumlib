## xumlib - shell and network utility library

### Installation
    $ sudo npm xumlib
    $ sudo npm install -g git://github.com/hakt0r/xumlib.git

### Usage:
    var xl = require('xumlib');

### Functions:
  * sh : (cmd,args,callback)
  * script : (cmd,callback)
  * scriptlines : (cmd,opts)
  * waitproc : (opts={})
  * running : (name, callback)
  * killall : (name, callback, fail)
  * forkdm : (args,callback)
  * readproc : (opts)
  * send : (msg,callback)
  * getmac : (l)
  * ip2long : (ip)
  * long2ip : (ip)
  * dotmask2cidr : (mask)
  * cidr2dotmask : (cidr)
  * guess_ip_fromnet : (net, callback)
  * guess_net : (ip, callback)
  * guess_dev : (ip, callback)
  * guess_gw : (dev)

### Copyrights
  * c) 2012-2013 Sebastian Glaser <anx@ulzq.de>

### Licensed under GNU GPLv3

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
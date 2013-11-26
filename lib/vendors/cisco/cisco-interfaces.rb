# parsing of cisco | huawei configs for interface based info
def cisco_interface
    
 last_deliminator = '!' if @Device.vendor =~ /cisco/
 last_deliminator = '#' if @Device.vendor =~ /huawei/
 # controller name
 
 if @Device.line =~ /^controller\s(.*)/ && @Device.last == last_deliminator
   i = $1   
   @Controller = Cisco_Controller.new i
   @Controller.device = @Device.hostname
 end
 
 if @Controller
 
   # descriptions line based on the interface configs is expected to be after the interface name
   if @Device.line =~ /descriptions\s/ && @Device.last =~ /^controller\s/
     @Controller.descriptions = @Device.line
   end
   # descriptions appears to be the last entry in the config
   if @Device.last =~ /descriptions\s/ && @Device.line == last_deliminator
     @Controller.descriptions = @Device.last
   end
   
   # basic handling of channel groups
   if @Device.line =~ /channel-group/
     @Controller.channelGroup = true
   end
   
   # TODO: might need to handle the descriptions being anywhere in the config of a controller
   
   if @Controller and @Device.line == last_deliminator
     @Controller.parse_descriptions         
     @Controller.to_descriptions_summary if $opt["mode"] == "descriptions"
     @Controller = nil           
   end
        
 end # if @Controller
 
 # interface name
 if @Device.line =~ /^interface\s(.*)/ && @Device.last == last_deliminator
   i = $1
   i.gsub!(/ point-to-point/,'')
   @Interface = Cisco_Interface.new @Device.hostname , i
 end

 # we dont need to look for any other commands untill we have our interface object    
 if @Interface
   # descriptions line
   if @Device.line =~ /descriptions\s/ && @Device.last =~ /^interface\s/
     @Interface.descriptions = @Device.line          
   end
   
   # encapsulation
   if @Device.line =~ /\sencapsulation\s(.*)/
     @Interface.encapsulation = $1
   end
   
   if @Device.line =~ /\sencapsulation\s(.*)\s.*/
     @Interface.encapsulation = $1
   end
    
   # link-protocol huawei only
   if @Device.line =~ /\slink-protocol\s(.*)/
     @Interface.encapsulation = $1
   end
   
   # descriptions line huawei only
   if @Device.line =~ /descriptions\s/ && last =~ /\slink-protocol\s/
     @Interface.descriptions = line
   end
   
   if @Device.line =~ / tunnel @mode mpls/ && @Interface.name =~ /tunnel/i
     @Interface.encapsulation = "tunnel-mpls"
   end
   
   # vrf
   if @Device.line =~ / ip vrf forwarding (.*)/
     @Interface.vrf = $1
   end
   
   if @Device.line =~ / ip binding vpn-instance (.*)/
     @Interface.vrf = $1
   end
   
   # ip address
   if @Device.line =~ / ip address (\d+.\d+.\d+.\d+)\s(\d+.\d+.\d+.\d+)(\sstandby)?/
     ip = IPAddress "#{$1}/#{$2}"
     @Interface.connected_routes.routes.push "#{ip.address}/#{ip.prefix}"
   end
   

   # state
   if @Device.line =~ /\s+shutdown/
     @Interface.state = "shutdown"
   end
 
 end

  # ip route 0.0.0.0 0.0.0.0 150.1.6.1
  if not @Device.line =~ /vrf/ and @Device.line =~ /^ip route (\d+.\d+.\d+.\d+)\s(\d+.\d+.\d+.\d+)\s(.*)/
    ip = IPAddress "#{$1}/#{$2}"
    @Device.static_routes.push "#{ip.address}/#{ip.prefix} #{$3}"
  end

  if @Device.line =~ /^ip route vrf\s([^\s]+)\s(\d+.\d+.\d+.\d+)\s(\d+.\d+.\d+.\d+)\s(.*)/
    ip = IPAddress "#{$2}/#{$3}"    
    @Device.static_routes.push "vrf #{@Device.trac["cisco vrf name to rd"][$1]} #{ip.address}/#{ip.prefix} #{$4}"
  end
  
  # vrf to rd
  if @Device.line =~ /^ip vrf\s(.*)/ && @Device.last == last_deliminator
    @Device.trac["last vrf"] = $1
  end
  
  if @Device.line =~ /\srd\s(\d+:\d+)/ and @Device.trac["last vrf"] != ""
    @Device.trac["cisco vrf name to rd"][@Device.trac["last vrf"]] = $1
  end
  
  if @Device.line == last_deliminator
    @Device.trac["last vrf"] = ""
  end
  
 # end of inteface config, parse once we have the minium required info
 # TODO: good idea or bad idea to be ignoring shutdown interfaces
 if @Interface and @Interface.state != "shutdown" and @Device.line == last_deliminator and not $opt["ignore-interface-state"]
   @Interface.parse_description     
   @Device.interfaces.push @Interface    
   @Interface = nil         
 end

end # end if cisco | huawei

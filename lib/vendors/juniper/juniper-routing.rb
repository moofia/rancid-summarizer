
# routing, devices types are only added when required.
# for now there is no routing class, will produce output in real time as we have no idea on the scale of this.

# parsing of juniper configs
def juniper_routing(line,last,trac,rancid_file)

   # follow the indentation so we know where we are
   if trac["physical_interface_indent"] >= 0
     trac["physical_interface_indent"] = trac["physical_interface_indent"] + 1 if line =~ /\{$/
     trac["physical_interface_indent"] = trac["physical_interface_indent"] - 1 if line =~ /\}$/
   end       

   # start of routing-instances
   
   #routing-instances {
   #    VPLS-MET010-SILV-INSIDE {
   #        instance-type vpls;
   #        vlan-id 1643;
   #        interface ge-2/1/6.1643;
   #        routing-interface irb.1643;
   #        route-distinguisher 16637:11643;
   #        vrf-target target:16637:11643;
   #        protocols {
   #            vpls {
   #                site-range 5;
   #                no-tunnel-services;
   #                site rb-srx-2.za {
   #                    site-identifier 2;
   #                    interface ge-2/1/6.1643;
   #                }
   #            }
   #        }
   #    }
   #
   if line =~ /routing-instances \{/
     trac["physical_interface_indent"] = 0
   end 
   
   if trac["physical_interface_indent"] == 1
     
     if line =~ /\w+ \{/
       trac["instance_name"] = line.gsub(/\s+/,'').gsub(/\{/,'')
     end
   
     if line =~ /instance-type vpls;/
       trac["instance_type"] = "vpls"
     end
     
     if line =~ /vlan-id (\d+);/
       trac["vla_id"] = $1
     end
     
     if line =~ / interface (.*);/
       trac["interface"] = $1
     end
     
     if line =~ /routing-interface (.*);/
       trac["routing_interface"] = $1
     end   
     
     if line =~ /route-distinguisher (.*);/
       trac["route_distinguisher"] = $1
     end   
     
     if line =~ /vrf-target target:(.*);/
       trac["vrf_target"] = $1
     end   
            
   end
   
   # display this only when trying to debug
  # if trac["physical_interface_indent"] > 0 and trac["instance_type"] == "vpls"
   #if trac["physical_interface_indent"] > 0
  #    puts "indent:#{trac["physical_interface_indent"]} instance_name:#{trac["instance_name"]} #{line}"
   #end
   
   
   # end of interface clear the state 
   if trac["physical_interface_indent"] == 1 && line =~ /\}/
    
     if trac["instance_type"] == "vpls"
       device = rancid_file.gsub(/.*\//,'').gsub(/.moo.net|.moofoo.net/,'')
       puts "#{device};#{trac["instance_name"]};#{trac["vla_id"]};#{trac["interface"]};#{trac["routing_interface"]};#{trac["route_distinguisher"]};#{trac["vrf_target"]}"
     end
     
     trac["instance_name"]       = ""
     trac["instance_type"]       = ""
     trac["vla_id"]              = ""
     trac["interface"]           = ""
     trac["routing_interface"]   = ""
     trac["route_distinguisher"] = ""
     trac["vrf_target"]          = ""
   end
   
   # end of indentation so we can process collected data
   if trac["physical_interface_indent"] == -1
     trac["instance_name"]       = ""
     trac["instance_type"]       = ""
     trac["vla_id"]              = ""
     trac["interface"]           = ""
     trac["routing_interface"]   = ""
     trac["route_distinguisher"] = ""
     trac["vrf_target"]          = ""
   end
  
end

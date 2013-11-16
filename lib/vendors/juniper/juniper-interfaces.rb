
# parsing of juniper configs for interface based info
def juniper_interface


  line = @Device.line
  last = @Device.last
  trac = @Device.trac
  rancid_file = @Device.rancid_file
  
  # collect interfaces that are in a vrf, this is need to set the usage_class correctly
   if trac["juniper_vrf"] == 0
     # must catch this error 
     # invalid byte sequence in UTF-8
     begin
       v_last = ""
       File.open(rancid_file).readlines.each do |v|    
         trac["juniper_vrf"] = 2 if  v_last =~ /instance-type\s(.*)/ 
         if  trac["juniper_vrf"] == 2 && v =~ /interface\s(.*);/
           trac["juniper"][$1] = 1
         end
         v_last = v
       end
       trac["juniper_vrf"] = 1
     rescue ArgumentError => e
       if $opt["debug"]
         puts "error: #{e}" 
       end
     end
     
   end

   # follow the indentation so we know where we are
   if trac["int_indent"]  >= 0
     trac["int_indent"] = trac["int_indent"] + 1 if line =~ /\{$/
     trac["int_indent"] = trac["int_indent"] - 1 if line =~ /\}$/
   end
   if trac["unit_indent"] >= 0
     trac["unit_indent"] = trac["unit_indent"] + 1 if line =~ /\{$/
     trac["unit_indent"] = trac["unit_indent"] - 1 if line =~ /\}$/
   end           

   # start of interfaces
   if line =~ /interfaces \{/
     trac["int_indent"] = 0
   end
   
   # physical interface name
   if trac["int_indent"] == 1 && line =~ /\{$/
     trac["physical_interface"] = line.gsub(/\s+/,'')
     trac["physical_interface"].gsub!(/\{/,'')
     trac["encap"] = "" if trac["encap"] == "flexible-ethernet-services"
   end
      
   # unit name
   if line =~ /unit\s\d+\s\{/
     trac["encap"] = "" if trac["encap"] == "flexible-ethernet-services"
     trac["unit_indent"] = 0
     trac["unit"] = line.gsub(/\s+/,'')
     trac["unit"].gsub!(/\{/,'')
     trac["unit"].gsub!(/unit/,'')
   end    
   
   # state of the physical interface of the unit, can be disabled seperately so we have
   # to keep track of both.
   if  trac["int_indent"]  > 0 && line =~ /disable;/
     trac["state"] = "disable" 
   end
   if  trac["unit_indent"] > 0 && line =~ /disable;/
     trac["unit_state"] = "disable" 
   end
   if  trac["int_indent"]  > 0 && line =~ /enable;/
     trac["state"] = "enable" 
   end
   if  trac["unit_indent"] > 0 && line =~ /enable;/
     trac["unit_state"] = "enable" 
   end
         
   #      fe-1/1/0 {
   #          speed 100m;
   #          mtu 1532;
   #          link-mode full-duplex;
   #          unit 0 {
   #              description "ct-cr-1.za--ct-nas-1.za-a:b2b:nas:100000:sp::sp-upha:ct-cr-1.za to ct-nas-1.za";
   #              family inet {
   #                  address 196.44.18.85/30;
   #              }
   #              family iso;
   #              family mpls;
   #          }
   #      }
         
   # interface desription and start of the interface creation
   if trac["int_indent"] > 0  && line =~ /description/
     trac["physical_interface_descr"] = line
     if trac.has_key? "unit" and trac["unit"].to_i == 0
       trac["interface"] = "#{trac["physical_interface"]}.0"
     else
       trac["interface"] = "#{trac["physical_interface"]}.#{trac["unit"]}"
       # insert kludge here to undo mistakes above as a way to transition this fix.
       trac["interface"].gsub!(/\.$/,'')
       
     end
     trac["descr"] = line.gsub(/;/,'')
     @Interface = Juniper_Interface.new @Device.hostname, trac["interface"]
     @Interface.description =  line.gsub(/;/,'')
     @Interface.vrf = "yes" if trac["juniper"].has_key? trac["interface"]
     @Interface.vrf = "yes" if trac["juniper"].has_key? trac["interface"] + '.0'
     @Interface.encapsulation = trac["encap"] if trac["encap"] != ""
     
     #puts "XXX juniper_interface #{trac["interface"]} --> #{line} "
     #puts "XXX juniper_interface --> #{@Interface.inspect}"
   end
   
   
   # interface vlan tags
   # vlan-tags outer 2191 inner 3547; 
   if trac["int_indent"] > 0  && line =~ /vlan-tags outer (\d+) inner (\d+)/
     outer = $1
     inner = $2
     if (outer =~ /\d+/ and inner =~ /\d+/ and @Interface)
       @Interface.vlan_tags = inner + "," + outer
     end
   end
   
   # vlan-id 3508; 
   
   if trac["int_indent"] > 0  && line =~ /vlan-id (\d+);/
     inner = $1
     if (inner =~ /\d+/ and @Interface)
       @Interface.vlan_tags = inner
     end
   end
     
   # encapsulation
   if trac["int_indent"] > 0  && line =~ /encapsulation (cisco-hdlc|frame-relay|flexible-ethernet-services);/
     trac["encap"] = $1
     trac["encap"].gsub!(/cisco-/,'')
   end

   # 802.3ad
   if trac["int_indent"] > 0  && line =~ /gigether-options \{/
     trac["802.3ad"] = true
   end
    
   if trac["int_indent"] > 0  && line =~ /802.3ad .*;/ && trac["802.3ad"]
     trac["encap"] = "lacp"
   end

   # ip address
   if trac["int_indent"] > 0  && last =~ /family inet \{/      
     trac["inet"] = 1     
   end
   
   if trac["inet"] == 1 && line =~ /\s+address\s(.*)\/(\d+);/
     if @Interface
       @Interface.connected_routes.routes.push "#{$1}/#{$2}"
     end        
   end
   

   # display this only when trying to debug
   #if trac["int_indent"] > 0
   # puts "indent:#{trac["int_indent"]} indent_unit:#{trac["unit_indent"]} #{line} ---> #{trac["physical_interface"]}:#{trac["unit"]} "
   #end
   
   # deal with frame-relay or flexible-ethernet-services interfaces where the physical interface must be graphed. this might be extended to other
   # mediums as we are notified of this problem, eg broadlink etc
   # this is a bit of a kludge at the moment.
   #
   # adding in 'at' interfaces
   #
   # this should be redone!
   
   process_physical = false
   
   process_physical = true if (trac["encap"] =~ /frame-relay|flexible-ethernet-services|lacp/) and line =~ /\}|\{/
   
   if process_physical == true
     if @Interface
       # TODO: is this check below really needed at this point ? 
       if @Interface.description =~ /\w+/
                  
         @Interface.encapsulation = trac["encap"]
         
         
         if trac["encap"] =~ /flexible-ethernet-services|lacp/    
           @Interface.name.gsub!(/\.0$/,'') if trac["unit"] == ""
         end
         @Device.interfaces.push @Interface 
         @Interface = nil
       end
     end
     # should we not be clearning more things here?
     trac["encap"] = ''
     trac["802.3ad"] = false
   end

   # end of the unit config, proceed to parse description and other collected data
   if trac["unit_indent"] == -1 && trac["int_indent"] == 1
     
     if trac["descr"] =~ /\w+/
      
       if @Interface and trac["state"] !~ /disable/
         # FIXME: massive kludge due to the amount of diffs between the original script having this "bug"
         # must be removed once this is live as this is a cosmetic / graph interpreting aid. 
         # This must be rewored as removal does not simply work.
         if trac["encap"] != "frame-relay"
           # only this line once script is live
           @Interface.encapsulation = trac["encap"]
         else
           @Interface.encapsulation = ""
         end
       end
       # FIXME: why is a nil hitting this part
       @Device.interfaces.push @Interface if @Interface != nil
       @Interface = nil
     end
     # clear trac
     trac["descr"] = ""
     trac["interface"] = ""
     trac["encap"] = ""
     trac["inet"] = ""
     trac["unit_state"] = ""
     trac["unit_indent"] = -2
     trac["unit"] = ""
     trac["physical_interface_descr"] = ""
     trac["802.3ad"] = false
     
   end
   
   # end of interface clear the state 
   if trac["int_indent"] == 1 && line =~ /\}/
     trac["state"] = ""
     # this only being done for encap
     trac["encap"] = "" if trac["encap"] == "flexible-ethernet-services"
     
   end
   # end of indentation so we can process collected data
   if trac["int_indent"] == -1
     trac["physical_interface"] = ""
     trac["unit"] = ""
     trac["encap"] = ""
   end
  
end

# FIXME: hate the way this is being done! refactor
#
# parsing of juniper configs for interface based info
def juniper_interface
  line = @Device.line
  last = @Device.last
  trac = @Device.trac
  rancid_file = @Device.rancid_file
  
  juniper_vrf_find_interfaces
  juniper_intenter
   
  trac["group_current"] = "" if trac["group_indent"] < 0
   
  # groups
  trac["group_indent"]        = 0 if line =~ /^groups \{/
  trac["group_name_is_next"]  = true if trac["group_indent"] == 0
  if trac["group_indent"]     > 0 and trac["group_name_is_next"] 
   trac["group_current"]      = @Device.line.gsub(/\s{/,"").gsub(/^\s+/,'')
   trac["group_name_is_next"] = false
  end
  
  # start of interfaces
  trac["physical_interface_indent"] = 0 if line =~ /interfaces \{/
   
  # physical interface name
  if trac["physical_interface_indent"] == 1 && line =~ /\{$/
    trac["physical_interface"] = line.gsub(/\s+/,'').gsub!(/\{/,'')
    trac["encap"] = "" if trac["encap"] == "flexible-ethernet-services"
  end
      
   # unit name
   if line =~ /unit\s\d+\s\{/
     trac["encap"] = "" if trac["encap"] == "flexible-ethernet-services"
     trac["unit_interface_indent"] = 0
     trac["unit"] = line.gsub(/\s+/,'').gsub(/\{/,'').gsub!(/unit/,'')
   end    
   
  # state of the physical interface of the unit, can be disabled seperately so we have
  # to keep track of both.
  trac["state"] = "disable" if  trac["physical_interface_indent"]  > 0 && line =~ /disable;/
  trac["unit_state"] = "disable" if  trac["unit_interface_indent"] > 0 && line =~ /disable;/
  trac["state"] = "enable" if  trac["physical_interface_indent"]  > 0 && line =~ /enable;/
  trac["unit_state"] = "enable" if  trac["unit_interface_indent"] > 0 && line =~ /enable;/
         
   # interface desription and start of the interface creation
   if trac["physical_interface_indent"] > 0  && line =~ /description/
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
   if trac["physical_interface_indent"] > 0  && line =~ /vlan-tags outer (\d+) inner (\d+)/
     outer = $1
     inner = $2
     if (outer =~ /\d+/ and inner =~ /\d+/ and @Interface)
       @Interface.vlan_tags = inner + "," + outer
     end
   end
   
   # vlan-id 3508; 
   
   if trac["physical_interface_indent"] > 0  && line =~ /vlan-id (\d+);/
     inner = $1
     if (inner =~ /\d+/ and @Interface)
       @Interface.vlan_tags = inner
     end
   end
     
   # encapsulation
   if trac["physical_interface_indent"] > 0  && line =~ /encapsulation (cisco-hdlc|frame-relay|flexible-ethernet-services);/
     trac["encap"] = $1
     trac["encap"].gsub!(/cisco-/,'')
   end

   # 802.3ad
   if trac["physical_interface_indent"] > 0  && line =~ /gigether-options \{/
     trac["802.3ad"] = true
   end
    
   if trac["physical_interface_indent"] > 0  && line =~ /802.3ad .*;/ && trac["802.3ad"]
     trac["encap"] = "lacp"
   end

   # ip address
   if trac["physical_interface_indent"] > 0  && last =~ /family inet \{/      
     trac["inet"] = 1     
   end
   
   if trac["inet"] == 1 && line =~ /\s+address\s(.*)\/(\d+);/
     if @Interface
       @Interface.connected_routes.routes.push "#{$1}/#{$2}"
     end        
   end
   
   # display this only when trying to debug
   #if trac["physical_interface_indent"] > 0
   # puts "indent:#{trac["physical_interface_indent"]} indent_unit:#{trac["unit_interface_indent"]} #{line} ---> #{trac["physical_interface"]}:#{trac["unit"]} "
   #end

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
         @Interface.group = trac["group_current"]
         @Device.interfaces.push @Interface 
         @Interface = nil
       end
     end
     # should we not be clearning more things here?
     trac["encap"] = ''
     trac["802.3ad"] = false
   end

   # end of the unit config, proceed to parse description and other collected data
   if trac["unit_interface_indent"] == -1 && trac["physical_interface_indent"] == 1
     
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
       if @Interface != nil
         @Interface.group = trac["group_current"]
         @Device.interfaces.push @Interface
       end
       @Interface = nil
     end
     # clear trac
     trac["descr"] = ""
     trac["interface"] = ""
     trac["encap"] = ""
     trac["inet"] = ""
     trac["unit_state"] = ""
     trac["unit_interface_indent"] = -2
     trac["unit"] = ""
     trac["physical_interface_descr"] = ""
     trac["802.3ad"] = false
     
   end
   
   # end of interface clear the state 
   if trac["physical_interface_indent"] == 1 && line =~ /\}/
     trac["state"] = ""
     # this only being done for encap
     trac["encap"] = "" if trac["encap"] == "flexible-ethernet-services"
   end
   
   # end of indentation so we can process collected data
   if trac["physical_interface_indent"] == -1
     trac["physical_interface"] = ""
     trac["unit"] = ""
     trac["encap"] = ""
   end
  
   juniper_groups_applied
end

# handles all the indentation tracking so we know where we are
def juniper_intenter  
   if @Device.trac["physical_interface_indent"] >= 0
     @Device.trac["physical_interface_indent"]   = @Device.trac["physical_interface_indent"] + 1 if @Device.line =~ /\{$/
     @Device.trac["physical_interface_indent"]   = @Device.trac["physical_interface_indent"] - 1 if @Device.line =~ /\}$/
   end
   if @Device.trac["unit_interface_indent"] >= 0
     @Device.trac["unit_interface_indent"]   = @Device.trac["unit_interface_indent"] + 1 if @Device.line =~ /\{$/
     @Device.trac["unit_interface_indent"]   = @Device.trac["unit_interface_indent"] - 1 if @Device.line =~ /\}$/
   end
   if @Device.trac["group_indent"] >= 0
     @Device.trac["group_indent"]   = @Device.trac["group_indent"] + 1 if @Device.line =~ /\{$/
     @Device.trac["group_indent"]   = @Device.trac["group_indent"] - 1 if @Device.line =~ /\}$/
   end   
end

def juniper_vrf_find_interfaces
  # collect interfaces that are in a vrf
   if @Device.trac["juniper_vrf"] == 0
     # must catch this error 
     # invalid byte sequence in UTF-8
     begin
       v_last = ""
       File.open(@Device.rancid_file).readlines.each do |v|    
         @Device.trac["juniper_vrf"] = 2 if  v_last =~ /instance-type\s(.*)/ 
         if  @Device.trac["juniper_vrf"] == 2 && v =~ /interface\s(.*);/
           @Device.trac["juniper"][$1] = 1
         end
         v_last = v
       end
       @Device.trac["juniper_vrf"] = 1
     rescue ArgumentError => e
       if $opt["debug"]
         puts "error: #{e}" 
       end
     end  
   end
end

# get a list of groups that have been applied. 
# later output will only be given for a group if it is applied.
def juniper_groups_applied
  if @Device.trac["group_end_needed"]
    @Device.line.gsub(/apply-groups \[ /,'').gsub(/ \];$/,'').split(" ").each do |g|
      @Device.groups[g] = true
    end
    @Device.trac["group_end_needed"] = false if @Device.line =~ / \];$/
  end
  
  if @Device.line =~ /^apply-groups/
    @Device.line.gsub(/apply-groups \[ /,'').gsub(/ \]$/,'').split(" ").each do |g|
      @Device.groups[g] = true
    end
         
    @Device.trac["group_end_needed"] = true if @Device.line !~ / \];$/
  end
  
end



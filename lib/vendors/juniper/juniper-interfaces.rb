# FIXME: hate the way this is being done! refactor
#
# parsing of juniper configs for interface based info
def juniper_interface
  line = @Device.line
  last = @Device.last
  trac = @Device.trac
  rancid_file = @Device.rancid_file
  
  # order of methods is critical
  juniper_vrf_find_interfaces
  juniper_intenter
  juniper_debug_2
  
  juniper_groups_tracking
  juniper_positional_tracking
  juniper_physical_interface_name
  juniper_unit_interface_name
  juniper_interface_state
  juniper_interface_description
  juniper_vlan_tags
  juniper_interface_other
  juniper_ip_address
  juniper_process_unit_interface
  juniper_physical_interface_indent_end
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

# knowing which vrf an interface is in is required by various summaries
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

# keep track of groups / name / position
def juniper_groups_tracking
  @Device.trac["group_current"]       = "" if @Device.trac["group_indent"] < 0
  @Device.trac["group_indent"]        = 0 if @Device.line =~ /^groups \{/
  @Device.trac["group_name_is_next"]  = true if @Device.trac["group_indent"] == 0
  if @Device.trac["group_indent"]     > 0 and @Device.trac["group_name_is_next"] 
    @Device.trac["group_current"]      = @Device.line.gsub(/\s{/,"").gsub(/^\s+/,'')
    @Device.trac["group_name_is_next"] = false
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
    @Device.line.gsub(/apply-groups \[ /,'').gsub(/ \];$/,'').split(" ").each do |g|
      @Device.groups[g] = true
    end
         
  @Device.trac["group_end_needed"] = true if @Device.line !~ / \];$/
  end
  
end

# state of the physical interface of the unit, can be disabled seperately so we have
# to keep track of both.
def juniper_interface_state
  @Device.trac["state"] = "enable" if  @Device.trac["physical_interface_indent"]  > 0 && @Device.line =~ /enable;/
  @Device.trac["state"] = "disable" if  @Device.trac["physical_interface_indent"]  > 0 && @Device.line =~ /disable;/
  @Device.trac["unit_state"] = "enable" if  @Device.trac["unit_interface_indent"] > 0 && @Device.line =~ /enable;/
  @Device.trac["unit_state"] = "disable" if  @Device.trac["unit_interface_indent"] > 0 && @Device.line =~ /disable;/
end

def juniper_vlan_tags
   
  # interface vlan tags
  # vlan-tags outer 2191 inner 3547; 
  if @Device.trac["physical_interface_indent"] > 0  && @Device.line =~ /vlan-tags outer (\d+) inner (\d+)/
    outer = $1
    inner = $2
    if (outer =~ /\d+/ and inner =~ /\d+/ and @Interface)
      @Interface.vlan_tags = inner + "," + outer
    end
  end
  
  # vlan-id 3508; 
  
  if @Device.trac["physical_interface_indent"] > 0  && @Device.line =~ /vlan-id (\d+);/
    inner = $1
    if (inner =~ /\d+/ and @Interface)
      @Interface.vlan_tags = inner
    end
  end

end

# ip address
def juniper_ip_address
  if @Device.trac["physical_interface_indent"] > 0  && @Device.last =~ /family inet \{/      
    @Device.trac["inet"] = 1     
  end
  
  if @Device.trac["inet"] == 1 && @Device.line =~ /\s+address\s(.*)\/(\d+);/
    if @Interface
      @Interface.connected_routes.routes.push "#{$1}/#{$2}"
    end        
  end
end

def juniper_interface_other
  # encapsulation
  if @Device.trac["physical_interface_indent"] > 0  && @Device.line =~ /encapsulation (cisco-hdlc|frame-relay|flexible-ethernet-services);/
    @Device.trac["encap"] = $1
    @Device.trac["encap"].gsub!(/cisco-/,'')
  end
  
  # 802.3ad
  if @Device.trac["physical_interface_indent"] > 0  && @Device.line =~ /gigether-options \{/
    @Device.trac["802.3ad"] = true
  end
   
  if @Device.trac["physical_interface_indent"] > 0  && @Device.line =~ /802.3ad .*;/ && @Device.trac["802.3ad"]
    @Device.trac["encap"] = "lacp"
  end
end

# more detailed debugging for juniper configs which will display the tracking
def juniper_debug_2
  # display this only when trying to debug
  if $opt["debug2"]
    if @Device.trac["physical_interface_indent"] > 0
     puts "#{@Device.hostname} [line #{@Device.trac["line_number"]}] indent:#{@Device.trac["physical_interface_indent"]} indent_unit:#{@Device.trac["unit_interface_indent"]} #{@Device.line} ---> #{@Device.trac["physical_interface"]}:#{@Device.trac["unit"]} "
    end
  end
end

def juniper_positional_tracking
  # start of interfaces
  @Device.trac["physical_interface_indent"] = 0 if @Device.line =~ /interfaces \{/
end

def juniper_physical_interface_name
  # physical interface name
  if @Device.trac["physical_interface_indent"] == 1 && @Device.line =~ /\{$/
    @Device.trac["is_inside_physical_interface"] = true
    interface = @Device.line.gsub(/\s+/,'').gsub!(/\{/,'')
    if interface !~ /\*/
      @Device.trac["physical_interface"] = interface
      @Device.trac["interface"] = interface
      # FIXME: why is this here ? 
      @Device.trac["encap"] = "" if @Device.trac["encap"] == "flexible-ethernet-services"
      @Interface = Juniper_Interface.new @Device.hostname, @Device.trac["interface"]
    end
  end
end

def juniper_unit_interface_name
  # unit name
  if @Device.line =~ /unit\s\d+\s\{/
    juniper_process_physical_interface
    @Device.trac["is_inside_unit_interface"] = true
    @Device.trac["encap"] = "" if @Device.trac["encap"] == "flexible-ethernet-services"
    @Device.trac["unit_interface_indent"] = 0
    @Device.trac["unit"] = @Device.line.gsub(/\s+/,'').gsub(/\{/,'').gsub!(/unit/,'')
    @Device.trac["physical_interface_descr"] = @Device.line
    if @Device.trac.has_key? "unit" and @Device.trac["unit"].to_i == 0
      @Device.trac["interface"] = "#{@Device.trac["physical_interface"]}.0"
    else
      @Device.trac["interface"] = "#{@Device.trac["physical_interface"]}.#{@Device.trac["unit"]}"
      # insert kludge here to undo mistakes above as a way to transition this fix.
      @Device.trac["interface"].gsub!(/\.$/,'')
    end
    #puts "#{@Device.trac["interface"]}--"
    @Interface = Juniper_Interface.new @Device.hostname, @Device.trac["interface"]
    
  end    
end


def juniper_interface_description
  # interface desription and start of the interface creation
  if @Interface
    if @Device.trac["physical_interface_indent"] > 0  && @Device.line =~ /description/
      @Device.trac["descr"] = @Device.line.gsub(/;/,'')
      @Interface.description =  @Device.line.gsub(/;/,'')
      @Interface.vrf = "yes" if @Device.trac["juniper"].has_key? @Device.trac["interface"]
      @Interface.vrf = "yes" if @Device.trac["juniper"].has_key? @Device.trac["interface"] + '.0'
      @Interface.encapsulation = @Device.trac["encap"] if @Device.trac["encap"] != ""
    end
  end

end

# end of physical interface indentation so we can process collected data
def juniper_physical_interface_indent_end
  if @Device.trac["physical_interface_indent"] == 1 && @Device.line =~ /\}/
    @Device.trac["is_inside_physical_interface"] = false
    @Device.trac["state"] = ""
    # this only being done for encap
    @Device.trac["encap"] = "" if @Device.trac["encap"] == "flexible-ethernet-services"
  end
  
  if @Device.trac["physical_interface_indent"] == -1
    @Device.trac["physical_interface"] = ""
    @Device.trac["unit"] = ""
    @Device.trac["encap"] = ""
  end
end

def juniper_process_physical_interface

    if @Interface
      # TODO: is this check below really needed at this point ? 
      if @Interface.description =~ /\w+/
        @Interface.encapsulation = @Device.trac["encap"]
        if @Device.trac["encap"] =~ /flexible-ethernet-services|lacp/    
          @Interface.name.gsub!(/\.0$/,'') if @Device.trac["unit"] == ""
        end
        @Interface.group = @Device.trac["group_current"]
        @Device.interfaces.push @Interface 
        @Interface = nil
      end
      # should we not be clearning more things here?
      @Device.trac["encap"] = ''
      @Device.trac["802.3ad"] = false
      @Device.trac["description"] = ""
    end

    
end

def juniper_trac_clear
  @Device.trac["descr"] = ""
  @Device.trac["interface"] = ""
  @Device.trac["encap"] = ""
  @Device.trac["inet"] = ""
  @Device.trac["unit_state"] = ""
  @Device.trac["unit_interface_indent"] = -2
  @Device.trac["unit"] = ""
  @Device.trac["physical_interface_descr"] = ""
  @Device.trac["802.3ad"] = false
  @Device.trac["physical_interface"] = ""
  @Device.trac["description"] = ""
end

# end of the unit config, proceed to parse description and other collected data
def juniper_process_unit_interface
  if @Device.trac["unit_interface_indent"] == -1 && @Device.trac["physical_interface_indent"] == 1
    @Device.trac["is_inside_unit_interface"] = false
    if @Interface and @Device.trac["state"] !~ /disable/
      @Device.trac["descr"] = "#{@Device.hostname} __ #{@Interface.name}" if @Device.trac["descr"] !~ /\w+/
        if @Device.trac["encap"] != "frame-relay"
          # only this line once script is live
          @Interface.encapsulation = @Device.trac["encap"]
        else
          @Interface.encapsulation = ""
        end
      # FIXME: why is a nil hitting this part
      if @Interface != nil
        @Interface.group = @Device.trac["group_current"]
        @Device.interfaces.push @Interface
      end
      @Interface = nil
    end
    juniper_trac_clear
  end
end















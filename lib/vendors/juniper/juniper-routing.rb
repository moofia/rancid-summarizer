
# parsing of juniper configs for routing related data
def juniper_routing
  juniper_indent_c_tags("physical_interface_indent")
  juniper_vpls  
end

# vpls
def juniper_vpls
  @Device.trac["physical_interface_indent"] = 0 if @Device.line =~ /routing-instances \{/

  if @Device.trac["physical_interface_indent"] == 1
    @Device.trac["instance_name"] = @Device.line.gsub(/\s+/,'').gsub(/\{/,'') if @Device.line =~ /\w+ \{/
    @Device.trac["instance_type"] = "vpls" if @Device.line =~ /instance-type vpls;/
    @Device.trac["vla_id"] = $1 if @Device.line =~ /vlan-id (\d+);/
    @Device.trac["interface"] = $1 if @Device.line =~ / interface (.*);/
    @Device.trac["routing_interface"] = $1 if @Device.line =~ /routing-interface (.*);/
    @Device.trac["route_distinguisher"] = $1 if @Device.line =~ /route-distinguisher (.*);/
    @Device.trac["vrf_target"] = $1 if @Device.line =~ /vrf-target target:(.*);/
  end
  
  if $opt["debug2"]
    if @Device.trac["physical_interface_indent"] > 0 and @Device.trac["instance_type"] == "vpls"
      if @Device.trac["physical_interface_indent"] > 0
        puts "indent:#{@Device.trac["physical_interface_indent"]} instance_name:#{@Device.trac["instance_name"]} #{@Device.line}"
      end
    end
  end

  # end of interface clear the state 
  if @Device.trac["physical_interface_indent"] == 1 && @Device.line =~ /\}/
    
    if @Device.trac["instance_type"] == "vpls"
      @Device.vpls.push "#{@Device.trac["instance_name"]};#{@Device.trac["vla_id"]};#{@Device.trac["interface"]};#{@Device.trac["routing_interface"]};#{@Device.trac["route_distinguisher"]};#{@Device.trac["vrf_target"]}"    
    end
    
    @Device.trac["instance_name"]       = ""
    @Device.trac["instance_type"]       = ""
    @Device.trac["vla_id"]              = ""
    @Device.trac["interface"]           = ""
    @Device.trac["routing_interface"]   = ""
    @Device.trac["route_distinguisher"] = ""
    @Device.trac["vrf_target"]          = ""
  end

  # end of indentation so we can process collected data
  if @Device.trac["physical_interface_indent"] == -1
    @Device.trac["instance_name"]       = ""
    @Device.trac["instance_type"]       = ""
    @Device.trac["vla_id"]              = ""
    @Device.trac["interface"]           = ""
    @Device.trac["routing_interface"]   = ""
    @Device.trac["route_distinguisher"] = ""
    @Device.trac["vrf_target"]          = ""
  end

end

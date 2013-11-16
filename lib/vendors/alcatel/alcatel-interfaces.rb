
# parsing of alcatel configs for interface based info
def alcatel_interface

  line = @Device.line
  last = @Device.last
  trac = @Device.trac
  # start or end of the 'Port Configuration'
  trac["alcatel_port_start"] = 1 if line =~ /^#--------------/ and last =~ /^echo "Port Configuration"/
  trac["alcatel_port_start"] = 0 if line =~ /^#--------------/ and last !~ /^echo "Port Configuration"/
  
  if trac["alcatel_port_start"] == 1
    # interface name
    if line =~ /^\s+port\s(.*)/
      @Interface = Alcatel_Interface.new @Device.hostname, $1
      @Interface.device = @device
    end
    # descriptions line
    if line =~ /descriptions\s/
      @Interface.descriptions = line
    end
    # encapsulation
    if line =~ /\sencap-type\s(.*)/
      @Interface.encapsulation = $1
    end
  end
  
  # start or end of the 'LAG Configuration'
  trac["alcatel_lag_start"] = 1 if line =~ /^#-+$/ and last =~ /^echo "LAG Configuration"/
  trac["alcatel_lag_start"] = 0 if line =~ /^#-+$/ and last !~ /^echo "LAG Configuration"/
  
  if trac["alcatel_lag_start"] == 1              
    # interface name
    if line =~ /\s+lag\s(\d+)/
      i = "lag-" + $1
      @Interface = Alcatel_Interface.new @Device.hostname , i
      @Interface.device = @device
      # TODO: temp kludge, not too sure if this is a kludge right now. 
      @Interface.encapsulation = "lag"
    end

    # descriptions line
    if line =~ /descriptions\s/
      @Interface.descriptions = line
    end
  end

  # end of 'Port Configuration' or 'LAG Configuration', parse once we have the minium required info
  # we are assuming the indentation is correct for the exit out of 'Port Configuration'
	if @Interface && line =~ /^\s\s\s\sexit$/
    @Interface = nil
  end
end

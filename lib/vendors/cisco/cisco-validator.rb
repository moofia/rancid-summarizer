
def validate_logger(group,message)
  delim = ';'
  delim = " --> " if $opt.has_key? "debug"
  puts "#{@Device.hostname}#{delim}#{group}#{delim}#{message}"
end

# collection of cisco configs for validation
def cisco_validate
  #validator_cisco_vty
  validator_cisco_generic
  #cisco_validate_null0(line,last,trac,rancid_file)
  #cisco_validate_netflow_exporter(line,last,trac,rancid_file)
end

# process of cisco collected data for processing
def validator_cisco_process
  #validator_cisco_process_vty
  validator_cisco_process_generic
  #validator_cisco_process_null0(trac,rancid_file)
  #validator_cisco_process_netflow_exporter(trac,rancid_file)
end

def validator_cisco_vty
  if @Device.line =~ /^line (vty|con|aux)\s/
    type = $1
    @Device.trac["vty"] = Hash.new unless @Device.trac["vty"].class == Hash     
    @Device.trac["vty"]["start"] = 1
    @Device.trac["vty"]["type"] = type
  end
  
  if @Device.trac.has_key? "vty" and @Device.trac["vty"]["start"] > 0
    if @Device.line =~ /\s+(password\s7.*)/
      @Device.trac["vty"]["line"] = $1
    end
    # access-class 7 in
    if @Device.line =~ /\s+access-class\s(.*)\s/ and @Device.trac["vty"]["type"] == "vty"
      @Device.trac["vty"]["acl"] = $1
    end
  end
  
end

def validator_cisco_process_vty
  if @Device.trac.has_key? "vty" and @Device.trac["vty"].has_key? "line"
    validate_logger("line","insecure \'#{trac["vty"]["line"]}\'")
  end
  if @Device.trac.has_key? "vty" and not @Device.trac["vty"].has_key? "acl"
    validate_logger("line","no vty acl")
  end
end

def validator_cisco_generic
  @Device.trac["generic"] = Hash.new unless @Device.trac["generic"].class == Hash  
  @Device.trac["generic"]["chassis"] = @Device.line if @Device.line =~ /^!Chassis type:/ 

  if @Device.trac["generic"]["chassis"] =~ /router/ and @Device.trac["generic"]["chassis"] !~ /Cat6k|WS-C|MSFC/
    
    $validator["cisco"]["global"]["true"].keys.each do |t|
      @Device.trac["generic"][t] = true if @Device.line =~ /#{$validator["cisco"]["global"]["true"][t]}/
    end
    $validator["cisco"]["global"]["false"].keys.each do |t|
      @Device.trac["generic"][t] = true if @Device.line =~ /#{$validator["cisco"]["global"]["false"][t]}/
    end
    
  end
end

def validator_cisco_process_generic
  if @Device.trac.has_key? "generic"
    if @Device.trac["generic"]["chassis"] =~ /router/ and @Device.trac["generic"]["chassis"] !~ /Cat6k|WS-C|MSFC/
      $validator["cisco"]["global"]["true"].keys.each do |t|
        display_name = t.gsub(/_/,' ')
        validate_logger("global","missing \'#{display_name}\'") if not @Device.trac["generic"].has_key? t
      end
      $validator["cisco"]["global"]["false"].keys.each do |t|
        display_name = t.gsub(/_/,' ')
        validate_logger("global","found \'#{display_name}\'") if @Device.trac["generic"].has_key? t
      end
    end  
  end
end

#!
#interface Null0
# no ip unreachables
#!
def cisco_validate_null0(line,last,trac,rancid_file)
  if $validator["cisco"].has_key? "null0" and $validator["cisco"]["null0"] == "unreachables"
  key = "null0"
  if line =~ /^interface Null0/ and last =~ /^!/
    trac[key] = Hash.new unless trac[key].class == Hash     
    trac[key]["start"] = 1
  end
  
  if trac.has_key? key and trac[key]["start"] > 0
    if line =~ /\sno ip unreachables/
      trac[key]["unreachables"] = true
    end
  end
  end
end

def validator_cisco_process_null0(trac,rancid_file)
  key = "null0"  
  if trac.has_key? "generic"
    device = device_name(rancid_file)
    if trac["generic"]["chassis"] =~ /router/ and trac["generic"]["chassis"] !~ /Cat6k|WS-C|MSFC/
      if trac.has_key? key and not trac[key].has_key? "unreachables"
        validate_logger(device,"security","missing \'no ip unreachables\' on Null0")
      end
    end  
  end
end

#ip flow-export destination
def cisco_validate_netflow_exporter(line,last,trac,rancid_file)
  key = "flow-export"
  if line =~ /^ip flow-export destination (.*) (.*)/
    trac[key] = Hash.new unless trac[key].class == Hash     
    trac[key]["destination"] = $1
    trac[key]["port"] = $2
  end
end

def validator_cisco_process_netflow_exporter(trac,rancid_file)
  key = "flow-export"
  if trac.has_key? key
    device = device_name(rancid_file)
    if $validator["netflow"].has_key? "destination"
      $validator["netflow"]["destination"].keys.each do |regex|
        if device =~ /#{regex}/
          if $validator["netflow"]["destination"][regex] != trac[key]["destination"]
            validate_logger(device,"netflow-export","#{trac[key]["destination"]} is not a valid destination")
          end
          if $validator["netflow"].has_key? "port" and $validator["netflow"]["port"].to_s != trac[key]["port"]
            validate_logger(device,"netflow-export","#{trac[key]["port"]} is not a valid port")
          end
        end
      end
      
    end
  end
end

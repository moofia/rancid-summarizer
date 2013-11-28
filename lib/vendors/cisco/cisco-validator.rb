
def validate_logger(device,group,message)
  delim = ';'
  delim = " --> " if $opt.has_key? "debug"
  puts "#{device}#{delim}#{group}#{delim}#{message}"
end

# collection of cisco configs for validation
def cisco_validate
  line = @Device.line
  last = @Device.last
  trac = @Device.trac
  rancid_file = @Device.rancid_file
  cisco_validate_vty(line,last,trac,rancid_file)
  cisco_validate_generic(line,last,trac,rancid_file)
  cisco_validate_null0(line,last,trac,rancid_file)
  cisco_validate_netflow_exporter(line,last,trac,rancid_file)
end

# process of cisco collected data for processing
def cisco_process
  trac = @Device.trac
  rancid_file = @Device.rancid_file
  cisco_process_vty(trac,rancid_file)
  cisco_process_generic(trac,rancid_file)
  cisco_process_null0(trac,rancid_file)
  cisco_process_netflow_exporter(trac,rancid_file)
end

def cisco_validate_vty(line,last,trac,rancid_file)
  if line =~ /^line (vty|con|aux)\s/
    type = $1
    trac["vty"] = Hash.new unless trac["vty"].class == Hash     
    trac["vty"]["start"] = 1
    trac["vty"]["type"] = type
  end
  
  if trac.has_key? "vty" and trac["vty"]["start"] > 0
    if line =~ /\s+(password\s7.*)/
      trac["vty"]["line"] = $1
    end
    # access-class 7 in
    if line =~ /\s+access-class\s(.*)\s/ and trac["vty"]["type"] == "vty"
      trac["vty"]["acl"] = $1
    end
  end
  
end

def cisco_process_vty(trac,rancid_file)
  device = @Device.rancid_file
  if trac.has_key? "vty" and trac["vty"].has_key? "line"
    validate_logger(device,"line","insecure \'#{trac["vty"]["line"]}\'")
  end
  if trac.has_key? "vty" and not trac["vty"].has_key? "acl" and device !~ /-cs-|^lg/
    validate_logger(device,"line","no vty acl")
  end
end

def cisco_validate_generic(line,last,trac,rancid_file)
  trac["generic"] = Hash.new unless trac["generic"].class == Hash  
  trac["generic"]["chassis"] = line if line =~ /^!Chassis type:/ 

  if trac["generic"]["chassis"] =~ /router/ and trac["generic"]["chassis"] !~ /Cat6k|WS-C|MSFC/
    
    $validate["cisco"]["true"].keys.each do |t|
      trac["generic"][t] = true if line =~ /#{$validate["cisco"]["true"][t]}/
    end
    $validate["cisco"]["false"].keys.each do |t|
      trac["generic"][t] = true if line =~ /#{$validate["cisco"]["false"][t]}/
    end
    
  end
end

def cisco_process_generic(trac,rancid_file)
  if trac.has_key? "generic"
    device = device_name(rancid_file)
    if trac["generic"]["chassis"] =~ /router/ and trac["generic"]["chassis"] !~ /Cat6k|WS-C|MSFC/
      $validate["cisco"]["true"].keys.each do |t|
        display_name = t.gsub(/_/,' ')
        validate_logger(device,"generic","missing \'#{display_name}\'") if not trac["generic"].has_key? t
      end
      $validate["cisco"]["false"].keys.each do |t|
        display_name = t.gsub(/_/,' ')
        validate_logger(device,"generic","found \'#{display_name}\'") if trac["generic"].has_key? t
      end
    end  
  end
end

#!
#interface Null0
# no ip unreachables
#!
def cisco_validate_null0(line,last,trac,rancid_file)
  if $validate["cisco"].has_key? "null0" and $validate["cisco"]["null0"] == "unreachables"
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

def cisco_process_null0(trac,rancid_file)
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

def cisco_process_netflow_exporter(trac,rancid_file)
  key = "flow-export"
  if trac.has_key? key
    device = device_name(rancid_file)
    if $validate["netflow"].has_key? "destination"
      $validate["netflow"]["destination"].keys.each do |regex|
        if device =~ /#{regex}/
          if $validate["netflow"]["destination"][regex] != trac[key]["destination"]
            validate_logger(device,"netflow-export","#{trac[key]["destination"]} is not a valid destination")
          end
          if $validate["netflow"].has_key? "port" and $validate["netflow"]["port"].to_s != trac[key]["port"]
            validate_logger(device,"netflow-export","#{trac[key]["port"]} is not a valid port")
          end
        end
      end
      
    end
  end
end

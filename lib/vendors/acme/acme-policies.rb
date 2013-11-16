
# parsing of acme local policy
def acme_local_policy


  line = @Device.line
  last = @Device.last
  trac = @Device.trac
  rancid_file = @Device.rancid_file
  
  # ; is the delimenator for output, we must make sure its not being used.
  line.gsub!(/;/,"_");

  if line =~ /^(\w+.*)$/
    trac["acme_section_name"] = $1    
  end
  
  # if we already have a policy we need to process the previous one
  if trac["acme_local_policy"] == 1 && trac["acme_local_acme_start"] == 1 && line =~ /^local-policy$/
    acme_local_policy_display trac, rancid_file
  end
  
  # start or end of the 'local-policy'
  if trac["acme_section_name"] =~ /^local-policy$/ && line =~ /^local-policy$/
    trac["acme_local_acme_start"] = 1 
    trac["acme_from-address"] = []
    trac["acme_to-address"] = []
    trac["acme_source-realm"] = []
    trac["acme_descriptions"] = ""
    trac["acme_next-hop"] = ""
    trac["acme_realm"] = ""
  end
  
  trac["acme_local_acme_start"] = 0 if trac["acme_section_name"] !~ /^local-policy$/
  

  if trac["acme_local_acme_start"] == 1 
    trac["acme_local_policy"] = 1
    
    # handle the variations of the to-address
    if line =~ /^\s+from-address$/
       trac["acme_from-address_start"] = 1     
    elsif line =~ /^\s+from-address\s+(.*)/
      trac["acme_from-address"].push($1)  
      trac["acme_from-address_start"] =  0
    end

    
    # handle variations of from-address
    if line =~ /^\s+to-address$/
      trac["acme_from-address_start"] = 0    
      trac["acme_to-address_start"] = 1
    elsif line =~ /^\s+to-address\s+(.*)/
      trac["acme_to-address"].push($1)    
      trac["acme_from-address_start"] = 0    
      trac["acme_to-address_start"] = 0
    end

    
    # handle variations of source-realm
    if line =~ /^\s+source-realm$/
      trac["acme_from-address_start"] = 0    
      trac["acme_to-address_start"] = 0
      trac["acme_source-realm_start"] = 1
    end
    if line =~ /^\s+source-realm\s+(.*)/ 
      trac["acme_source-realm"].push($1)
      trac["acme_from-address_start"] = 0    
      trac["acme_to-address_start"] = 0
      trac["acme_source-realm_start"] = 0
    end

    if trac["acme_from-address_start"] == 1 && line !~ /^\s+from-address$/
      line =~ /\s+(.*)/
      trac["acme_from-address"].push($1)
    end
    if trac["acme_to-address_start"] == 1 && line !~ /^\s+to-address$/
      line =~ /\s+(.*)/
      trac["acme_to-address"].push($1)
    end
    
    if line =~ /^\s+descriptions/ 
      trac["acme_source-realm_start"] = 0
      if line =~ /^\s+descriptions\s+(.*)/ 
        trac["acme_descriptions"] = $1
        
      end
    end
    
    if trac["acme_source-realm_start"] == 1 && line !~ /^\s+source-realm$/
        line =~ /\s+(.*)/
        trac["acme_source-realm"].push($1)
    end


    
    if last =~ /^\s+policy-attribute$/
      trac["acme_policy-attribute_start"] = 1  
    end

    if trac["acme_policy-attribute_start"] == 1

      if line =~ /^\s+next-hop/ 
        if line =~ /^\s+next-hop\s+(.*)/ 
          trac["acme_next-hop"] = $1
        end
      end
      
      if line =~ /^\s+realm/ 
        if line =~ /^\s+realm\s+(.*)/ 
          trac["acme_realm"] = $1
        end
      end
      
    end
    ##### 
    

    



  end
  
  #puts "XX: #{line} --> #{trac["acme_local_acme_start"]}"
  
  # should be at the next section so we can now process the previous policy
  if trac["acme_local_acme_start"] == 0 && trac["acme_local_policy"] == 1
    trac["acme_local_policy"] = 0
    acme_local_policy_display trac, rancid_file
  end
  

  
end

# displaying acme local policy summary
def acme_local_policy_display(trac,rancid_file)  
  device = rancid_file.gsub(/.*\//,'').gsub(/.moo.net|.moofoo.net/,'')
  #puts "acme_local_policy_display should be done"
  # device ; from address ; to address ; source realm ; descriptions ; next-hop ; realm
  puts "#{device};#{trac["acme_from-address"].join(",")};#{trac["acme_to-address"].join(",")};#{trac["acme_source-realm"].join(",")};#{trac["acme_descriptions"]};#{trac["acme_next-hop"]};#{trac["acme_realm"]}"
  #puts
end


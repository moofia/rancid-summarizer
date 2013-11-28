def scriptDirectory
  File.expand_path($0).gsub(/\/bin\/.*/,'')
end

def commandLineOption
  # options
  begin
    $opt = Getopt::Long.getopts(
      ["--debug",  Getopt::BOOLEAN],
      ["--debug2",  Getopt::BOOLEAN],
      ["--help",   Getopt::BOOLEAN],
      ["--with-warnings",  Getopt::BOOLEAN],
      ["--ignore-interface-state",   Getopt::BOOLEAN],
      ["--mode",   Getopt::OPTIONAL],
      ["--filter", Getopt::OPTIONAL],
      ["--rancid_dir", Getopt::OPTIONAL]
      )
  rescue Getopt::Long::Error => error
    puts "#{@script} -> error #{error.message}"  
    puts 
    help
  end

  help if $opt["help"]

end

def postChecks
  
  if not $opt["rancid_dir"]
    log("error: rancid_dir not set!")
    exit 2
  end

  if not File.directory? $opt["rancid_dir"]
    log("error: invalid rancid_dir of \"#{$opt["rancid_dir"]}\"")
    exit 2
  end

end

def loadConfigs
  begin
    $config = YAML::load(File.read("#{scriptDirectory}/etc/rancid-summarizer.yaml"))
  rescue => error
    puts "#{@script} -> yaml error #{error.message} in etc/rancid-summarizer.yaml}"  
    exit 2
  end
  begin
    $validator = YAML::load(File.read("#{scriptDirectory}/etc/rancid-validator.yaml"))
  rescue => error
    puts "#{@script} -> yaml error #{error.message} in etc/rancid-validator.yaml}"  
    exit 2
  end
end

def barf (msg)
  STDERR.puts "#{@script} -> error: #{msg}!"
  exit 1
end

# generic debugger which exists once displaying
def debug (what)
  ap what
  exit 2
end

# basic help
def help
  @script = File.basename $0 
puts <<HELP
  usage: #{@script} --mode [descriptions]--filter [regex] --debug

  --filter [regex]           regex filter (optional, defaults to everything)
  --mode                     routes, vpls, vlan-tagging, validator
  --debug                    extra log messages for debugging
  --debug2                   extra extra log messages for debugging (can be a bit hairy)
  --rancid_dir               directory of where rancid data is stored (can only be used in validation mode)
  --ignore-interface-state   ignore the interface state
  --with-warnings            will display warnings to STDERR
  --help

HELP

exit
end

# generic logger to file
def log(msg)
 @script = File.basename $0 
 logfile = $config["settings"]["log_directory"] + "/#{@script}.log"
 if $config["settings"]["log_file"]
   File.open(logfile, 'a') do |file|
     now = Time.new.strftime("%Y-%m-%d %H:%M:%S")
     file.puts "#{@script} #{now} -> #{msg}"
   end
 end
 puts "#{@script} -> #{msg}"
end

def processSummaries
  
  #debug @Device.trac["cisco vrf name to rd"]
  
  
  # process all the summaries
  @Device.interfaces.each do |interface|
    display = true
    if @Device.vendor == "juniper"
      if interface.group =~ /\w/
        if not @Device.groups.has_key? interface.group
          display = false 
          @warnings.push "warning #{@Device.hostname} #{interface.name} configured in group \"#{interface.group}\" yet group is not applied"
        end
      end
    end
    
    if display
      interface.connected_routes.to_routes_summary if $opt["mode"] == "routes"
      interface.to_vlan_tagging_summary            if $opt["mode"] == "vlan-tagging"
      #puts "#{interface.name} --> #{interface.description}"
    end
  
  end
  @Device.summarizeStaticRoutes if $opt["mode"] == "routes"
  processVpls if $opt["mode"] == "vpls"
  
  validator_cisco_process if $opt["mode"] == "validator"
  #debug @Device.groups
end

def rancid_exclude_directory(directory)
  exclude = false
  if $config.has_key? "rancid"
    if $config["rancid"].has_key? "exclude groups"
      if $config["rancid"]["exclude groups"].class == Array
        $config["rancid"]["exclude groups"].each do |exclude_directory|
          exclude = true if exclude_directory == directory
        end
      end
    end
  end
  exclude
end

def display_warnings
  if $opt["with-warnings"]
    @warnings.each do |warning|
      $stderr.puts "#{@script} -> #{warning}"
    end
  end
end

def processVpls
  @Device.vpls.each do |summary|
    puts "#{@Device.hostname};#{summary}"
  end
end

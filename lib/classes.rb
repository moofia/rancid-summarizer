# Device class
class Device
  attr_writer :hostname, :vendor, :interfaces, :trac, :line, :last, :rancid_file, :static_routes
  attr_reader :hostname, :vendor, :interfaces, :trac, :line, :last, :rancid_file, :static_routes
  
  def initialize(hostname, vendor)
    @interfaces = []
    @static_routes = []
    @trac = {}
    @hostname = hostnameStripDomain(hostname)
    @vendor = vendor
    tracDefaults
    @last = ""
    @line = ""
  end

  def hostnameStripDomain(new_hostname)
    # strip domain name
    if $config["descriptions"]["domain_strip"]
      $config["descriptions"]["domain"].each do |d|
       new_hostname.gsub!(/.#{d}/,'')
      end
    end
    @hostname = new_hostname
  end
  
  def summarizeStaticRoutes
    @static_routes.each do |route|
      puts "static route;#{@hostname};#{route}"
    end
    
  end
  
 def tracDefaults
    # tracking
    @trac["int_indent"]  = -2
    @trac["unit_indent"] = -2
    @trac["unit_state"]  = ""
    # collected data
    @trac["descr"] = ""
    @trac["interface"] = ""
    @trac["encap"] = "" 
    @trac["state"] = ""
    # alcatel uniq
    @trac["alcatel_port_start"] = 0
    @trac["alcatel_lag_start"]  = 0
    # juniper uniq
    @trac["juniper"]     = {}
    @trac["juniper_vrf"] = 0
    @trac["inet"]        = ""
  end

end # Class Device

# ConnectedRoutes class
class ConnectedRoutes
  attr_writer :device, :interface , :routes
  attr_reader :device, :interface , :routes
  
  def initialize(device,interface)
    @routes    = []
    @DeviceName = device
    @interface = interface
  end

  def routes=(new_routes)
    @routes = new_routes
  end
  
  def to_routes_summary
    count = 0
    type = "connected route"
    @routes.each do |ipWithMask|
      address, netmask = ipWithMask.split("/")
      if address =~ /\d+\.\d+\.\d+\.\d+/ && netmask =~ /\d+/
        prep = ""
        prep = "/" if netmask =~ /^\d+$/
        type = "connected route secondary" if count > 0
        puts "#{type};#{@DeviceName};#{@interface};#{address};#{prep}#{netmask}"
      end
      count = count + 1
    end
  end
end # Class ConnectedRoutes

# Controller class
class Controller
  attr_writer :descriptions, :name, :device, :channelGroup
  attr_reader :descriptions, :name, :channelGroup
  
  def initialize(name)

    @name = name
    # mostly being done like this so i keep track of them, will clean up once i got a scope of the requirements
    @descriptions, @channelGroup = "", false
    
  end
  
  def descriptions=(new_descriptions)
    @descriptions = new_descriptions
    # basic descriptions line clean up
    @descriptions.gsub!(/^\s+/,'')
    @descriptions.gsub!(/descriptions\s+/,'')
    @descriptions.gsub!(/descriptions/,'')
    @descriptions.gsub!(/"/,'')
    @descriptions.gsub!(/\s+$/,'')
    
  end
  
  # no validation done right now, we just taking the raw descriptions line and passing it along. 
  # its not used for much right now.
  # we will want this later for root cause and for channelized controller monitoring.
  def parse_descriptions
    if @descriptions == "" || @descriptions.nil? and @channelGroup == false
      @descriptions = "UNUSED" 
    end
    
    if (@descriptions == "" || @descriptions.nil?) and @channelGroup == true
      @descriptions = "USED" 
    end      
    
    @is_valid_descriptions = true
  end
    
  def to_descriptions_summary
  end # to_descriptions_summary
  
end # Class Controller

# Interface class
class Interface
  attr_writer :description, :encapsulation, :status, :name, :device, :vrf, :address, :netmask, :state, :vlan_tags, :connected_routes
  attr_reader :mnemonic, :description, :telco, :speed_multiplier, :config_summary_done, :state, :valid, :name, :vlan_tags, :connected_routes
  
  def initialize(device, name)
    
    @name = name
    @DeviceName = device
    # mostly being done like this so i keep track of them, will clean up once i got a scope of the requirements
    @valid, @status, @encapsulation, @mnemonic, @descriptions, @is_valid_descriptions = false, "", "", "", "", false
    @telco, @circuit, @DeviceName, @config_summary_done, @vrf, @address, @netmask, @state,@l12type = "", "", "", false, "", "", "", "", ""
    @vlan_tags = ""
    @connected_routes = ConnectedRoutes.new device, @name
  end
  
  # FIXME: These methods are placeholders
  def description=(new_description)
    @description = new_description
  end

  def telco=(new_telco)
    @telco = new_telco
  end
  
  def mnemonic=(new_mnemonic)
    @mnemonic = new_mnemonic
  end
  
  def speed=(new_speed)
    @speed = new_speed
  end
  
  def circuit=(new_circuit)
    @circuit = new_circuit
  end
  
  def l12type=(new_l12type)
    @l12type = new_l12type
  end

  def encapsulation=(new_encapsulation)
    @encapsulation = new_encapsulation
  end
  
  def descriptions_extra=(new_descriptions_extra)
    @descriptions_extra = new_descriptions_extra
  end
  
  def vlan_tags=(new_tags)
     @vlan_tags = new_tags
  end
  
  def to_vlan_tags_summary
     if @is_valid_description
       @config_summary_done = true

       # incase no instance variable is set we set it to something that we can catch, also to ensure column count
       # in the summary is always intact
       self.instance_variables.each do |i|
         # descriptions_extra can be empty
         next if i =~ /descriptions_extra/
         self.instance_variable_set i,"xxxxx" if ((self.instance_variable_get i) == "")
       end  

       if @name !~ /^lo/i and @vlan_tags =~ /\d+/
         if @mnemonic != "unused"
           inner, outer = @vlan_tags.split(/,/)
           puts "#{@DeviceName};#{@name};#{@mnemonic};#{inner};#{outer}"
         end
       end
     end
  end  
   
  def to_descriptions_summary
  end
  
  def to_routes_summary
      if @address =~ /\d+\.\d+\.\d+\.\d+/ && @netmask =~ /\d+/
        #puts "to_routes_summary;#{@DeviceName};#{@name};#{@address};#{@netmask}"
      end
  end
  
 
  def parse_description
  end
  
  private
  
  # defaults for usage class
  def usage_class_guess
  end
  
  # defaults for encapsulation
  def encapsulation_guess
  end
end

# Cisco class will inherit from Controller
class Cisco_Controller < Controller
 
end

# Alcatel class will inherit from Interface
class Alcatel_Interface < Interface
  
  def l12type
    # bit of a guess on the default for alcatel's 
    case @name
      when /lag-/i
         @l12type = "lag"
      else
        @l12type = "tengig-ethernet"
    end
  end # def l12type
  
end

# Cisco class will inherit from Interface
class Cisco_Interface < Interface
  def l12type
    # guess for cisco's
    case @name
    when /fast/i
      @l12type = "fast-ethernet"
    when /gig/i
      @l12type = "gigabit-ethernet"
    when /ten/i
      @l12type = "tengig-ethernet"
    when /atm/i
      @l12type = "atm"
    when /pos/i
      @l12type = "pos"
    when /tunnel/i
      @l12type = "tunnel"
    when /atm.*\.\d+/i
      @l12type = "pvc"
    # TODO: lol total messup with ethernet being set to digital-leased
    when /^ethernet|serial/i
      @l12type = "digital-leased"
    when /multi/i
      @l12type = "digital-leased"
    end
  end
end

# Alcatel class will inherit from Interface
class Juniper_Interface < Interface
  attr_writer :unit
  attr_reader :unit
  
  def l12type

    # guess for junipers's    
    # order is important due to case statement
    # FIXME: its probably totally wrong. Loopback must not be set to ten-gig too and cstm
    case @name
    when /^fe/i
      @l12type = "fast-ethernet"
    when /^ge/i
      @l12type = "gigabit-ethernet"
    when /^irb/i
      @l12type = "gigabit-ethernet"
    when /^lo|^lt|^xe|^ae|^cstm1|^vlan|^fxp/i
      @l12type = "tengig-ethernet"
    when /^gr/i
      @l12type = "tunnel"
    when /pos/i
      @l12type = "pos"
    when /^so/i
      @l12type = "sonet"
    when /tunnel/i
      @l12type = "tunnel"
    when /^at.*\.\d+/i
      @l12type = "pvc"
    when /^t\d|^e|^ds|^lsq/i
      @l12type = "digital-leased"
    when /^at/i
      @l12type = "atm"
    end

  end
end


# Device class
class Device
  attr_writer :hostname, :vendor, :interfaces, :trac, :line, :last, :rancid_file, :static_routes, :groups, :vpls
  attr_reader :hostname, :vendor, :interfaces, :trac, :line, :last, :rancid_file, :static_routes, :groups, :vpls
  
  def initialize(hostname, vendor)
    @interfaces = []
    @static_routes = []
    @trac = {}
    @groups = {}
    @vpls = []
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
      type = "static route"
      if route =~ /vrf\s(\d+:\d+)\s(\d.*)/
        route = "#{$1};#{$2}"
        type = "static route vrf"
        
      end
      puts "#{type};#{@hostname};#{route}"
    end
    
  end
  
 def tracDefaults
    # tracking
    @trac["physical_interface_indent"]  = -2
    @trac["unit_interface_indent"] = -2
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
    @trac["juniper vrf interface"]     = {}
    @trac["juniper_vrf"] = 0
    @trac["family inet"]        = ""
    @trac["group_end_needed"] = false
    @trac["group_start"] = false 
    @trac["group_indent"] = -1
    @trac["group_name_is_next"] = false
    @trac["is_inside_physical_interface"] = false
    @trac["is_inside_unit_interface"] = false
    @trac["description"] = ""
    @trac["line_number"] = 0
    @trac["indent_routing_instance"] = -1 
    @trac["indent_static_routes"] = -1
    @trac["indent_static_routes_expanded"] = -1
    @trac["static_routes_expanded"] = ""
    @trac["routing_instance_type"] = ""
    @trac["cisco vrf name to rd"]     = {}
    @trac["last vrf"] = ""
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
  attr_writer :description, :encapsulation, :status, :name, :device, :vrf, :address, :netmask, :state, 
  :vlan_tags, :connected_routes, :group
  attr_reader :mnemonic, :description, :telco, :speed_multiplier, :config_summary_done, :state, :valid, :name, 
  :vlan_tags, :connected_routes, :group
  
  def initialize(device, name)
    
    @name = name
    @DeviceName = device
    @group = ""
    # mostly being done like this so i keep track of them, will clean up once i got a scope of the requirements
    @valid, @status, @encapsulation, @mnemonic, @is_valid_descriptions = false, "", "","", false
    @telco, @circuit, @config_summary_done, @vrf, @address, @netmask, @state,@l12type = "", "", false, "", "", "", "", ""
    @vlan_tags = ""
    @connected_routes = ConnectedRoutes.new device, @name
    @description = "#{@DeviceName}__#{@name}"
  end
  
  # FIXME: These methods are placeholders
  def description=(new_description)
    # basic description line clean up
    new_description.gsub!(/^\s+/,'')
    new_description.gsub!(/description\s+/,'')
    new_description.gsub!(/description/,'')
    new_description.gsub!(/"/,'')
    new_description.gsub!(/'/,'')
    new_description.gsub!(/\s+$/,'')
    new_description.gsub!(/\s+/,' ')
    new_description.gsub!(/[^0-9A-Za-z\s\\\/\(\)-\._&@'=:]/, '')
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
  
  def to_vlan_tagging_summary
    if @vlan_tags =~ /\d+/
      inner, outer = @vlan_tags.split(/,/)
      puts "vlan tagging;#{@DeviceName};#{@name};#{inner};#{outer}"
     end
  end  
   
  def to_descriptions_summary
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


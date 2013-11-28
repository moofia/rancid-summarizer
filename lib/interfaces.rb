
def parse_interface
  case @Device.vendor
  when "cisco"
    cisco_interface if $opt["mode"] =~ /routes/
  when "huawei"
    cisco_interface if $opt["mode"] =~ /routes/
  when "juniper"
    juniper_interface if $opt["mode"] =~ /routes/
    juniper_routing   if $opt["mode"] =~ /vpls/
  when "alcatel"
    alcatel_interface if $opt["mode"] =~ /routes/
  when "acme"
    acme_local_policy if $opt["mode"] =~ /policy/
  end
end

def parse_configuration
  case @Device.vendor
  when "cisco"
    cisco_interface if $opt["mode"] =~ /routes|vlan-tagging/
    cisco_validate  if $opt["mode"] =~ /validater/
  when "huawei"
    cisco_interface if $opt["mode"] =~ /routes/
  when "juniper"
    juniper_interface if $opt["mode"] =~ /routes|vlan-tagging/
    juniper_routing   if $opt["mode"] =~ /vpls/
  when "alcatel"
    alcatel_interface if $opt["mode"] =~ /routes/
  when "acme"
    acme_local_policy if $opt["mode"] =~ /policy/
  end
end
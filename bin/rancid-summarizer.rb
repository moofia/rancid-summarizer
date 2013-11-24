#!/usr/bin/env ruby

# massive refactoring in progress

require 'rubygems'
require 'ap'
require 'yaml'
require 'getopt/long'
require 'ipaddress'
  
script_dir = File.expand_path($0).gsub(/\/bin\/.*/,'')
require "#{script_dir}/lib/base"
require "#{script_dir}/lib/classes"
require "#{script_dir}/lib/interfaces"
require "#{script_dir}/lib/vendors/alcatel/alcatel-interfaces"
require "#{script_dir}/lib/vendors/cisco/cisco-interfaces"
require "#{script_dir}/lib/vendors/juniper/juniper-interfaces"
require "#{script_dir}/lib/vendors/acme/acme-policies"

@script = $0.split('/').last

# exit on ctrl-c
trap("INT") do
  puts
  exit 2
end

commandLineOption
loadConfigs
postChecks

@warnings = []

# default is descriptions
$opt["mode"] = "routes" if not $opt.has_key? "mode"
 
# by default we want all devices to be matched
@filter = $config["settings"]["filter_default"]
@filter = $opt["filter"] if $opt.has_key? "filter"

# location of checked out rancid data, this is not the loation of the racid repo
rancid_dir = $config["settings"]["rancid_dir"]

if $opt.has_key? "rancid_dir"
  rancid_dir = $opt["rancid_dir"]
end

# open the rancid directory and look for router.db files, once we know which vendor type a device
# is we are able to parse the file based on vendor type.
Dir.foreach(rancid_dir) do |directory|
  next if directory =~ /^\.|^CVS/
  next if rancid_exclude_directory(directory)
  next if not File.directory? "#{rancid_dir}/#{directory}"
  
  db = "#{rancid_dir}/#{directory}/router.db"
  if File.exists? db    
    File.open(db).readlines.each do |l|
      next if l =~ /^#/
      next if l =~ /^$/
      (hostname,vendor,status) = l.split(/:/)
      next if status !~ /up|down/
      next if vendor !~ /juniper|cisco|huawei|alcatel|acme/
 
      # create main device object
      @Device = Device.new hostname, vendor
      @Device.rancid_file = "#{rancid_dir}/#{directory}/configs/#{hostname}"
      
      # filter what devices we want, by default all
      next if @Device.rancid_file !~ /#{@filter}/
      @Device.trac["line_number"] = 0
      if File.exists? @Device.rancid_file
        log("debug: file #{@Device.rancid_file} --> #{@Device.vendor}") if $opt["debug"]
        File.open(@Device.rancid_file).readlines.each do |line|
          # must catch this error 
          # invalid byte sequence in UTF-8
          begin
            line.chomp!
            line.gsub!(/\s+$/,'')
            @Device.line = line
            parse_interface          
            @Device.last = @Device.line
          rescue ArgumentError => e
            if $opt["debug"]
              puts "line --> #{line}"
              puts "error: #{e}"
            end
          end
          @Device.trac["line_number"] = @Device.trac["line_number"] + 1;
        end # File.open(c).readlines
        
        processSummaries

      end # File.exists? c

    end # File.open(db).readlines
  end # File.exists? db
end #  Dir.foreach

display_warnings



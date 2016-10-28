require 'fileutils'
require 'json'

do_run = true

openstudio_path = ARGV[0]

if !openstudio_path
  puts "usage: ruby run.rb /path/to/cli/openstudio.exe'"
  exit
end

# clean out old files
osw_files = []
Dir.glob("office_2013*/*").each do |p|
  if /in.osw$/.match(p)
    osw_files << p
  else
    FileUtils.rm_rf(p) if do_run
  end
end

# update measures
#cmd = "#{openstudio_path} measure -t ./measures" 
#system(cmd)

# run the osw files
threads = []
osw_files.each do |osw|
  if do_run
    threads << Thread.new { cmd = "#{openstudio_path} run --debug -w #{osw}" ; system(cmd) } 
  end
end
threads.each {|t| t.join}

# collect the results
results = {}
osw_files.each do |osw|
  osw_out = File.join(File.dirname(osw), "out.osw")
  if File.exists?(osw_out)
    File.open(osw_out, 'r') do |f|
      results[osw] = JSON.parse(f.read, {symbolize_names: true})
    end
  end
end

# print the results
osw_files.each do |osw|
  puts osw
  if results[osw].nil?
    puts "  No results"
  else
    puts "  #{results[osw][:completed_status]}"
    results[osw][:steps].each do |step|
      if step[:measure_dir_name] == "StandardReports"
        step[:result][:step_values].each do |step|
          if step[:name] == "site_energy_use_ip"
            puts "  #{step[:value]} MBtu"
          end
        end
      end
    end
  end
end

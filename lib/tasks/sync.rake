task :sync_gologin_settings do
  require 'net/http'
  require 'uri'

  uri = URI.parse("https://api.gologin.com/browser/")
  request = Net::HTTP::Get.new(uri)
  request["Accept"] = "*/*"
  request["Authorization"] = "Bearer #{user.gologin_api_token}"
  request["Connection"] = "keep-alive"

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end
  self.gologin_profile_name = JSON.parse(response.body)["name"]
  self.save!
end

task sync: :environment  do
  print "update counts..."
  TinderAccount.update_counts(2)

  print "scheduler..."
  Schedule.run_all
  puts "done"

  print "sync jobs..."
  User.all.each {|u| u.k8s.sync_jobs }
  puts "done"

  # sync robert/prince gologins
  begin
    TinderAccount.alive.where(user_id: [3,5]).all.map {|t| t.update_gologin_name}
  rescue => e
    puts "error updating gologin names"
    puts e
  end
end

task sync_new_gologins_robert: :environment do
  SLEEP_TIME = ENV.fetch("SLEEP", 5)
  u = User.find_by(name: 'Robert')
  # next unless (u.name == "Robert" || u.name == "Robert2")
  # ids = profiles[profiles.keys[0]]

  ids = u.gologin_all_profiles
  next unless ids
  ids.each do |id|
    if id.nil?
      puts id
    else
      ta = TinderAccount.where(gologin_profile_id: id, user: u)
      next if ta.exists?
      ta = ta.first_or_create
      ta.sync_gologin
      # puts "creating new #{ta.id}"
      sleep SLEEP_TIME.to_i
    end
  end
end

task sync_new_gologins_prince: :environment do
  SLEEP_TIME = ENV.fetch("SLEEP", 5)
  u = User.find_by(name: 'Prince')
  # next unless (u.name == "Robert" || u.name == "Robert2")
  # ids = profiles[profiles.keys[0]]

  ids = u.gologin_all_profiles
  next unless ids
  ids.each do |id|
    if id.nil?
      puts id
    else
      ta = TinderAccount.where(gologin_profile_id: id, user: u)
      next if ta.exists?
      ta = ta.first_or_create
      ta.sync_gologin
      # puts "creating new #{ta.id}"
      sleep SLEEP_TIME.to_i
    end
  end
end

task sync_new_existing_gologins: :environment do
  puts "start existing new gologin"
  User.find_each { |u| u.sync_new_gologins }
end

task sync_existing_gologins: :environment do
  User.find_each { |u| u.sync_gologins }
end

task sync_limit_of_like: :environment do
  User.all.each {|u| u.k8s.sync_limit_of_like }
end

task sync_deleted_gologins: :environment do
  User.find_each { |u| u.sync_delete_gologins }
end

task sync_gologin_proxies: :environment do
  TinderAccount
    .where.not(proxy_ip: nil)
    .where(proxy_city: nil).map do |ta|
      s = Geocoder.search(ta.proxy_ip).try(:first);
      next unless s.try(:city);
      ta.update_attribute(:proxy_city, s.try(:city));
      ta.update_attribute(:proxy_region, s.region);
      ta.update_attribute(:proxy_hostname, s.data["hostname"]);
      ta.update_attribute(:proxy_org, s.data["org"])
    end
end

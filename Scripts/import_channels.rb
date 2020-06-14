require 'cfpropertylist'
require 'json'
require 'open-uri'

base_url = "http://monitoring.krakow.pios.gov.pl"
config_url = base_url + "/dane-pomiarowe/wczytaj-konfiguracje"

html = open(base_url).read
stations_data = nil

html.lines.each do |l|
    if l =~ /stations: (\[\{.*\}\])/
        stations_data = JSON.parse($1)
        break
    end
end

if stations_data.nil?
    puts "Error: no stations data found"
    exit 1
end

data = Net::HTTP.post(URI(config_url), "measType=Auto").body
config = JSON.parse(data)

all_channels = config['config']['channels']
all_stations = config['config']['stations']

stations = all_stations.map do |j|
    pm10_channel = all_channels.detect { |c| c['station_id'] == j['id'] && c['param_id'] == 'pm10' }
    data = stations_data.detect { |d| d['detailsPath'].end_with?("/#{j['id']}") }

    if pm10_channel && data
        {
            'id': j['id'],
            'name': j['name'],
            'channelId': pm10_channel['channel_id'],
            'lat': data['position']['lat'],
            'lng': data['position']['lng']
        }
    else
        nil
    end
end.compact

output_path = File.expand_path(File.join(__FILE__, '..', '..',
    'SmogWatch WatchKit Extension', 'Stations.plist'))

plist = CFPropertyList::List.new
plist.value = CFPropertyList.guess(stations)
plist.save(output_path, CFPropertyList::List::FORMAT_XML, formatted: true)

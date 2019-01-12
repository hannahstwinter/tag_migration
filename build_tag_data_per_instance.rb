require 'json'

def utf8_encode_commas_in_tag(tag)
  tag.gsub(',', '%2C')
end

def get_data_for_instance_id(instance_id, device_data)
  data = {}
  device = device_data.find { |device| device['id'] == instance_id }
  data['region'] = device ? device['region'] : nil
  data['ddi'] = device ? device['ddi'] : nil
  data
end

def build_instance_data(output_file, ddi, region, instance_id, tags, tags_under_field_limit, i)
  ind = i || -1

  if tags_under_field_limit
    output_file << "#{ddi} #{instance_id} #{region} com.rackspace.mycloud.tags.#{ind} #{tags_under_field_limit}\n"
  end

  if tags && tags.join(',').length > 255
    tag_string = tags.shift
    while tags.length > 1 && ((tag_string + ',' + tags[ind+1]).length < 255)
      tag_string = tag_string + ',' + tags.shift
    end
    build_instance_data(output_file, ddi, region, instance_id, tags, tag_string, ind+1)
  elsif tags && tags.join(',').length <= 255
    build_instance_data(output_file, ddi, region, instance_id, nil, tags.join(','), ind+1)
  end
end

def format_instance_data(instance_tags, device_data, output_file, log_file)
  count = 0
  total = instance_tags.length
  ddis = []
  instances = []
  instance_tags.each do |instance_id, tags|
    region_and_ddi = get_data_for_instance_id(instance_id, device_data)
    region = region_and_ddi['region']
    ddi = region_and_ddi['ddi']

    if region
      formatted_tags = tags.map { |tag| utf8_encode_commas_in_tag(tag) }
      build_instance_data(output_file, ddi, region.downcase, instance_id, formatted_tags, nil, nil)
      ddis << ddi
      instances << instance_id
    else
      log_file << "No region data for instance: #{instance_id}\n"
    end
    count+=1
    puts "Processing... #{count}/#{total}" if count % 100 == 0
  end
  log_file << "\n"
  log_file << "Unique DDI count: #{ddis.uniq.length}\n"
  log_file << "\n"
  log_file << "Instance count: #{instances.length}\n"
end

instance_tags = File.read('instance_id_to_tags.json') # output from cass_tags_to_json.rb
instance_tags_hash = JSON.parse(instance_tags)

device_data = File.read('servers_with_region_data.json') # file from Encore team
device_data_hash = JSON.parse(device_data)

output_file = File.open('tag_data_per_instance.log', 'w') # final output to deliver to TesOps
log_file = File.open('instances_not_found.log', 'w')

format_instance_data(instance_tags_hash, device_data_hash, output_file, log_file)

output_file.close
log_file.close

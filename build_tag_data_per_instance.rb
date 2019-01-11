require 'json'

def utf8_encode_commas_in_tag(tag)
  tag.gsub(',', '%2C')
end

def get_region_for_instance_id(instance_id, device_data)
  device = device_data.find { |device| device["id"] == instance_id }
  device ? device["region"] : nil
end

def build_instance_data(output_file, ddi, region, instance_id, tags, tags_under_char_limit, i)
  ind = i || -1

  if tags_under_char_limit
    output_file << "#{ddi} #{instance_id} #{region} com.rackspace.mycloud.tags.#{ind} #{tags_under_char_limit}\n"
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
  instance_tags.each do |instance_id, instance_data|
    ddi = instance_data['ddi']
    tags = instance_data['tags']
    region = get_region_for_instance_id(instance_id, device_data)

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

instance_tags = File.read('instance_id_to_tags.json')
instance_tags_hash = JSON.parse(instance_tags)

device_data = File.read('servers-20181112-162813.json') # file from Encore team
device_data_hash = JSON.parse(device_data)

output_file = File.open('tag_data_per_instance.log','w')
log_file = File.open('instances_not_found.log','w')

format_instance_data(instance_tags_hash, device_data_hash, output_file, log_file)

output_file.close
log_file.close

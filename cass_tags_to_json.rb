require_relative 'helper_methods'
  # json_should_skip - skips if line does not include json
  # clean - unescapes string and strips whitespace
require 'json'

def format_tags_from_cass_dump(tags_file, output, info_log, device_data)
  id_to_tags = {}
  total_instances = 0
  firstgen_instances = 0
  nextgen_instances = 0
  deleted_or_inactive_instances = 0
  null_entity_map_ddis = []
  active_server_ids = []

  device_data.each do |server|
    active_server_ids << server['id']
  end

  tags_file.each do |line|
    next if json_should_skip line

    parsed_line = JSON.parse(clean(line))
    ddi = parsed_line["ddi"]

    if parsed_line["entity_map"]
      parsed_line["entity_map"].each do |id, tags|
        total_instances+=1
        puts "Processing instance number #{total_instances}" if total_instances % 100 == 0

        unless active_server_ids.include?(id)
          deleted_or_inactive_instances+=1
          next
        end

        unless id && id.include?('-') # dash in id indicates next gen
          firstgen_instances+=1
          next
        end

        nextgen_instances+=1

        if tags
          id_to_tags[id] = JSON.parse(tags)
        else
          info_log << "No tag data - ddi: #{ddi}, id: #{id}\n"
          next
        end
      end
    else
      null_entity_map_ddis << ddi
    end
  end

  output << id_to_tags.to_json

  info_log << "total instances: #{total_instances}\n"
  info_log << "firstgen instances: #{firstgen_instances}\n"
  info_log << "nextgen instances: #{nextgen_instances}\n"
  info_log << "deleted or inactive instances: #{deleted_or_inactive_instances}\n"
  info_log << "\n"
  info_log << "null entity map count: #{null_entity_map_ddis.length}\n"
  info_log << "\n"
  info_log << "null entity map: #{null_entity_map_ddis.inspect}\n"
end

input = File.open('cass_tag_dump.json', 'r') # output from Cassandra database dump
output = File.open('instance_id_to_tags.json', 'w')
info_log = File.open('instance_id_to_tags_info.log', 'w')

device_data = File.read('servers_with_region_data.json') # file from Encore team
device_data_hash = JSON.parse(device_data)

format_tags_from_cass_dump(input, output, info_log, device_data_hash)

output.close
info_log.close

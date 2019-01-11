require_relative 'helper_methods'
  # json_should_skip - skips if line does not include json
  # clean - unescapes string and strips whitespace
require 'json'

def format_tags_from_cass_dump(tags_file, output, error_output)
  id_to_tags = {}
  total_instance_ids = 0
  null_entity_map_ddis = []
  tags_file.each do |line|
    next if json_should_skip line

    hashed_line = JSON.parse(clean(line))

    ddi = hashed_line["ddi"]

    null_entity_map_ddis << ddi unless hashed_line["entity_map"]

    hashed_line["entity_map"] && hashed_line["entity_map"].each do |id, tags|
      total_instance_ids+=1
      id_to_tags[id] = { ddi: ddi, tags: JSON.parse(tags) } if tags
      error_output << "ddi: #{ddi} => id: #{id}\n" unless tags
    end
  end

  output << id_to_tags.to_json

  error_output << "total instances: #{total_instance_ids}\n"
  error_output << "\n"
  error_output << "null entity map: #{null_entity_map_ddis.inspect}\n"
  error_output << "null entity map count: #{null_entity_map_ddis.length}\n"
end

input = File.open('cass_tag_dump.json','r')
output = File.open('instance_id_to_tags.json','w')
error_output = File.open('instance_id_to_tags_error.log','w')

format_tags_from_cass_dump(input, output, error_output)

output.close
error_output.close

require_relative 'helper_methods'
  # json_should_skip - skips if line does not include json
  # clean - unescapes string and strips whitespace
require 'json'

def format_tags_from_cass_dump(tags_file, output, error_output)
  id_to_tags = {}
  total_instances = 0
  firstgen_instances = 0
  nextgen_instances = 0
  null_entity_map_ddis = []
  tags_file.each do |line|
    next if json_should_skip line

    hashed_line = JSON.parse(clean(line))

    ddi = hashed_line["ddi"]

    null_entity_map_ddis << ddi unless hashed_line["entity_map"]

    hashed_line["entity_map"] && hashed_line["entity_map"].each do |id, tags|
      total_instances+=1
      unless id && id.include?('-') # dash in id indicates next gen
        firstgen_instances+=1
        next
      end
      nextgen_instances+=1

      if tags
        id_to_tags[id] = JSON.parse(tags) if tags
      else
        error_output << "ddi: #{ddi} => id: #{id}\n"
        next
      end
    end
  end

  output << id_to_tags.to_json

  error_output << "total instances: #{total_instances}\n"
  error_output << "firstgen instances: #{firstgen_instances}\n"
  error_output << "nextgen instances: #{nextgen_instances}\n"
  error_output << "\n"
  error_output << "null entity map: #{null_entity_map_ddis.inspect}\n"
  error_output << "null entity map count: #{null_entity_map_ddis.length}\n"
end

input = File.open('cass_tag_dump.json', 'r') # output from Cassandra database dump
output = File.open('instance_id_to_tags.json', 'w')
error_output = File.open('instance_id_to_tags_error.log', 'w')

format_tags_from_cass_dump(input, output, error_output)

output.close
error_output.close

require 'json'
require_relative 'helper_methods'
  # json_should_skip - skips if line does not include json

def get_sorted_cass_tag_string(instance_tags_hash, instance_id)
  instance_tags_hash[instance_id] &&
  instance_tags_hash[instance_id].sort &&
  instance_tags_hash[instance_id].sort.join(',')
end

def verify_tag_data(server_details, output_file, instance_tags_hash)
  server_tag_data = {}
  server_details.each do |line|
    next if json_should_skip line

    server = JSON.parse(line)
    server_id = server['server']['id']
    server_tag_data[server_id] = {}

    tags = ''
    ind = 0
    until tags.nil?
      indexed_tag_key = "com.rackspace.mycloud.tags.#{ind}"
      tags = server['server']['metadata'][indexed_tag_key]

      server_tag_data[server_id][indexed_tag_key] = tags if tags

      ind+=1
    end
  end

  tags_verified = {}
  tags_verified_count = 0
  tags_unable_to_be_verified = {}
  tags_unable_to_be_verified_count = 0

  server_tag_data.each do |instance_id, tags|
    sorted_cass_tag_string = get_sorted_cass_tag_string(instance_tags_hash, instance_id)

    server_tags = []
    tags.each { |_k, tags| server_tags.push tags }

    sorted_server_tag_string = server_tags && server_tags.join(',').split(',').sort.join(',')

    if (sorted_cass_tag_string == sorted_server_tag_string)
      tags_verified_count+=1
      tags_verified[instance_id] = server_tags
    else
      tags_unable_to_be_verified_count+=1
      tags_unable_to_be_verified[instance_id] = server_tags
    end
  end

  output_file << "Verified tags count = #{tags_verified_count}"
  output_file << "Unable to verify tag update count = #{tags_unable_to_be_verified_count}"
  output_file << "\n"
  output_file << "Unable to verify tag update:\n"
  output_file << tags_unable_to_be_verified
  output_file << "Verified tags:\n"
  output_file << tags_verified
end

server_details = File.open('get_server_details_output.log', 'r')
instance_tags = File.read('instance_id_to_tags.json') # output from cass_tags_to_json.rb
instance_tags_hash = JSON.parse(instance_tags)

output_file = File.open('tag_verification.log', 'w')

verify_tag_data(server_details, output_file, instance_tags_hash)

server_details.close
output_file.close

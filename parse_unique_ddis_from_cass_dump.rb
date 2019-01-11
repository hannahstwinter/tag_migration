require 'json'
require_relative 'helper_methods'
  # json_should_skip - skips if line does not include json
  # clean - unescapes string and strips whitespace

def get_unique_ddis(tags_file, output)
  ddis = []
  tags_file.each do |line|
    next if json_should_skip line

    hashed_line = JSON.parse(clean(line))

    ddis << hashed_line["ddi"]
  end
  ddis.uniq.sort.each do |ddi|
    output << "#{ddi}\n"
  end
end

input = File.open('cass_tag_dump.json','r')
output = File.open('unique_ddis_from_cass_tag_dump.txt','w')

get_unique_ddis(input, output)

output.close

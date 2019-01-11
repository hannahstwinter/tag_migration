# determine if line should be skipped in the process of parsing Cass tag data dump
def json_should_skip(line)
  !line.match(/{/)
end

# unescape and strip whitespace
def clean(line)
  unescape(line).strip!
end

# remove excessive escaping backslashes
def unescape(line)
  line.gsub(/\\{2}/, "\\")
end

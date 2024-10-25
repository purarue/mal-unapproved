require "json"

require "sinatra"
require "haml"

# Don't read from the file if it hasn't changed
# since the last time we read the disk
class JsonCache
  attr_reader :filepath, :modtime, :cached_value

  def initialize(filepath)
    abort "Filepath passed to cache initialization does't exist" unless File.exist?(filepath)
    @filepath = filepath
    @modtime = mod_time
    @cached_value = read_from_json
  end

  # get the modification time of the file
  def mod_time
    File.mtime(@filepath)
  end

  # read the json file
  def read_from_json
    JSON.parse File.new(@filepath).read
  end

  def get
    mtime = mod_time
    # use cached value
    if @modtime == mtime
      @cached_value
      # update file modification time and re-read updated json file
    else
      @modtime = mtime
      @cached_value = read_from_json
    end
  end
end

$server_dir = File.expand_path(__dir__)
$json_file = File.join($server_dir, "unapproved.json")
$json_info = File.join($server_dir, "unapproved_info.json")
$json_tar_name = "unapproved.tar.gz".freeze
$json_tar = File.join($server_dir, $json_tar_name)
$not_found_file = File.join($server_dir, "views", "404.html")
abort "the cache json file, #{$json_file} does not exist" unless File.exist?($json_file)
abort "the cache info file, #{$json_info} does not exist" unless File.exist?($json_info)

$id_cache = JsonCache.new($json_file)
$info_cache = JsonCache.new($json_info)

# Uses $json_file and request_type (an symbol)
# to read the local json cache and return
# a list of urls that are the unapproved entries
def read_json(request_type)
  case request_type
  when :manga
    @json_key = "unapproved_manga".freeze
    @url_part = "manga".freeze
  else
    @json_key = "unapproved_anime".freeze
    @url_part = "anime".freeze
  end
  @parsed_json = $id_cache.get()
  @parsed_info = $info_cache.get()
  @ids = @parsed_json[@json_key].map(&:to_s)
  @info = @parsed_info[@json_key]
  @data = {}
  @ids.each do |i|
    @id_url = "https://myanimelist.net/#{@url_part}/#{i}".freeze
    @data[i] = if @info.key?(i)
        @info[i]
      else
        { "name".freeze => @id_url, "type".freeze => "?".freeze, "nsfw".freeze => false }
      end
    @data[i]["url".freeze] = @id_url
  end
  [@ids, @data]
end

def file_updated_minutes_ago
  @mins_ago = ((Time.now - File.mtime($json_file)) / 60).round
  "This was updated #{@mins_ago} minute#{@mins_ago == 1 ? "".freeze : "s".freeze} ago"
end

set :haml, { :format => :html5 }
set :public_folder, File.dirname(__FILE__) + "/public"
set :sessions, false
set :environment, :production
set :port, 5123

def controller(request_type)
  @ids, @data = read_json request_type
  @updated_desc = file_updated_minutes_ago
  [request_type, @ids, @data, @updated_desc]
end

get "/" do
  @request_type, @ids, @data, @updated_desc = controller(:anime)
  haml :index
end

get "/anime" do
  @request_type, @ids, @data, @updated_desc = controller(:anime)
  haml :index
end

get "/manga" do
  @request_type, @ids, @data, @updated_desc = controller(:manga)
  haml :index
end

get "/raw" do
  `cd "#{$server_dir}"; rm "#{$json_tar_name}"; tar cvzf "#{$json_tar_name}" unapproved.json unapproved_info.json`
  send_file($json_tar, { :disposition => "attachment".freeze, :filename => File.basename($json_tar) })
end

# using https://github.com/purarue/darker_errors
not_found do
  send_file $not_found_file
end

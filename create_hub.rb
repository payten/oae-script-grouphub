#!/usr/bin/env jruby

require 'net/http'
require 'rubygems'
require 'json'
require 'markaby'
#require 'random'

@dry_run = false

@url = URI.parse("http://localhost:8080")
@user = "admin"
@pass = "admin"

puts "-- This is a script to create a Course Hub content page for a group"
puts "-- for use with Sakai OAE 1.2"


if ARGV.size === 1
  @groupid = ARGV[0]
else
  raise Exception.new, "groupid required - pass as argument" 
end

def get_json(path, raw = false)
    Net::HTTP.start(@url.host, @url.port) do |http|
		#print "-- GET: #{path}\n"
        req = Net::HTTP::Get.new(path)
        req.basic_auth @user, @pass
        response = http.request(req)
		
		if response.code.to_s === "404" then
			return nil
		end
		#puts response
		#puts response.body
        if raw
            return response.body()
        else
            return JSON.parse(response.body())
        end
    end
end

def post_json(path, json)
  if @dry_run then
    puts "POST: #{path}"
    puts json
  else
    prim_post(path, {
		  ":content" => json,
		  ":operation" => "import",
		  ":replace" => "true",
		  ":replaceProperties" => "true",
		  ":contentType" => "json"
	  })
  end
end

def prim_post(path, formData)
  if @dry_run then
    "prim-POST: #{path}"
  else
  	Net::HTTP.start(@url.host, @url.port) do |http|
          req = Net::HTTP::Post.new(path)
          req.basic_auth @user, @pass
  		    req.add_field("Referer", "#{@url.to_s}/dev")
          req.set_form_data(formData)

          return http.request(req)
      end
  end
end

def post_batch(requests)
  if @dry_run then    
    print "\n~~ Batch-POST: " 
    print requests.collect {|r| r["url"]}.join(", ")
    return "dry_run"
  else
    Net::HTTP.start(@url.host, @url.port) do |http|
        req = Net::HTTP::Post.new("/system/batch")
        req.basic_auth @user, @pass
		    req.add_field("Referer", "#{@url.to_s}/dev")	
        req.set_form_data({"requests" => JSON.generate(requests)})

        return http.request(req)
    end
  end
end

def generateWidgetId()
	"id" + (1_000_000 + rand(10_000_000 - 1_000_000)).to_s	
end

def convert_to_content_json(json)
  new_json = {}
  json.each do |k, v|
    if v.kind_of? Array
      new_json[k] = {}
      v.each_with_index do |val, i| 
        new_json[k]["__array__#{i}__"] = convert_to_content_json(val)
      end
    elsif v.kind_of? Hash
      new_json[k] = convert_to_content_json(v)
    else 
      new_json[k] = v
    end
  end
  new_json
end

def do_stuff
  # 0. Create the hub's ID
  hub_content_id = generateWidgetId()
  hub_subcontent_id = generateWidgetId()
  puts "creating a hub page: #{hub_content_id}"
  
  hub_docstructure = {
    "#{hub_content_id}" => {
      "rows" => [
        {
          "id" => "#{generateWidgetId()}",
          "columns" => [{
              "width" => 0.5,
              "elements" => []
            },
            {
              "width" => 0.5,
              "elements" => []
            }],
        },
        {
          "id" => "#{generateWidgetId()}",
          "columns" => [{
              "width" => 0.5,
              "elements" => []
              },
              {
                "width" => 0.5,
                "elements" => []
              }],
        },
        {
          "id" => "#{generateWidgetId()}",
          "columns" => [{
              "width" => 1,
              "elements" => []
            }]
        }        
      ]
    }
  }
  
  # add top row lhs htmlblock
  top_lhs_htmlblock_id = generateWidgetId()
  hub_docstructure[hub_content_id][top_lhs_htmlblock_id] = {
    "htmlblock" => {
      "content" => "<h1>Course Name Goes Here</h1>",
      "sakai:indexed-fields" => "content",
      "sling:resourceType" => "sakai/widget-data"
    }
  }
  hub_docstructure[hub_content_id]["rows"][0]["columns"][0]["elements"].push({
    "type" => "htmlblock",
    "id" => top_lhs_htmlblock_id
  })
  
  top_lhs_htmlblock_id = generateWidgetId()
  hub_docstructure[hub_content_id][top_lhs_htmlblock_id] = {
    "htmlblock" => {
      "content" => "<p>Course Details Go Here</p><ul><li>And here</li><li>And here</li></ul>",
      "sakai:indexed-fields" => "content",
      "sling:resourceType" => "sakai/widget-data"
    }
  }
  hub_docstructure[hub_content_id]["rows"][0]["columns"][0]["elements"].push({
    "type" => "htmlblock",
    "id" => top_lhs_htmlblock_id
  })
  
  # add top row rhs embedcontent
  embedcontent_widget_id = generateWidgetId()
  hub_docstructure[hub_content_id][embedcontent_widget_id] = {
    "embedcontent" => {
      "description" => "",
      "details" => true,
      "download" => false,
      "embedmethod" => "thumbnail",
      "items" => [],
      "layout" => "single",
      "name" => true,
      "sakai:indexed-fields" => "title,description",
      "sling:resourceType" => "sakai/widget-data",
      "title" => "Couse Documents"
    }
  }
  hub_docstructure[hub_content_id]["rows"][0]["columns"][1]["elements"].push({
    "type" => "embedcontent",
    "id" => embedcontent_widget_id
  })

  # 2nd row 1st column
  htmlblock_id = generateWidgetId()
  hub_docstructure[hub_content_id][htmlblock_id] = {
    "htmlblock" => {
      "content" => "<h1>Course Participants</h1>",
      "sakai:indexed-fields" => "content",
      "sling:resourceType" => "sakai/widget-data"
    }
  }
  hub_docstructure[hub_content_id]["rows"][1]["columns"][0]["elements"].push({
    "type" => "htmlblock",
    "id" => htmlblock_id
  })
  
  htmlblock_id = generateWidgetId()
  hub_docstructure[hub_content_id][htmlblock_id] = {
    "htmlblock" => {
      "content" => "<p>... create a participants widget for content profiles...</p>",
      "sakai:indexed-fields" => "content",
      "sling:resourceType" => "sakai/widget-data"
    }
  }
  hub_docstructure[hub_content_id]["rows"][1]["columns"][0]["elements"].push({
    "type" => "htmlblock",
    "id" => htmlblock_id
  })
  
  # 2nd row 2nd column
  htmlblock_id = generateWidgetId()
  hub_docstructure[hub_content_id][htmlblock_id] = {
    "htmlblock" => {
      "content" => "<h1>Lecture Theatre and Tutorial Room location</h1>",
      "sakai:indexed-fields" => "content",
      "sling:resourceType" => "sakai/widget-data"
    }
  }
  hub_docstructure[hub_content_id]["rows"][1]["columns"][1]["elements"].push({
    "type" => "htmlblock",
    "id" => htmlblock_id
  })
  
  googlemaps_id = generateWidgetId()
  hub_docstructure[hub_content_id][googlemaps_id] = {
    "googlemaps" => {
      "lat" => 40.7308803,
      "lng" => -73.9973273,
      "maphtml" => "Washington Square Park, 1 Washington Square N, New York, NY 10003, USA",
      "mapinput" => "Washington Square Park, NY, NY",
      "mapzoom" => 16,
      "sakai:indexed-fields" => "mapinput,maphtml",
      "sling:resourceType" => "sakai/widget-data"
    }
  }
  hub_docstructure[hub_content_id]["rows"][1]["columns"][1]["elements"].push({
    "type" => "googlemaps",
    "id" => googlemaps_id
  })
  
  # 3rd row 
  comments_id = generateWidgetId()
  hub_docstructure[hub_content_id][comments_id] = {
    "comments" => {
      "comments" => "",
      "direction" => "comments_FirstUp",
      "message" => {
        "sling:resourceType" => "sakai/messagestore"
      },
      "sling:resourceType" => "sakai/messagestore",
      "perPage" => 10,
      "sakai:allowanonymous" => false,
      "sakai:marker" => "id6394536",
      "sakai:notificationaddress" => "payten",
      "sakai:type" => "comment",
      "sling:resourceType" => "sakai/settings"
    }
  }
  hub_docstructure[hub_content_id]["rows"][2]["columns"][0]["elements"].push({
    "type" => "comments",
    "id" => comments_id
  })
  
  hub_docstructure_ugly = convert_to_content_json(hub_docstructure)

  #puts "---"  
  #puts hub_docstructure.inspect
  #puts "---"  
  #puts hub_docstructure_ugly.inspect
  #puts "---"
  
  ###########################################
  # Start to do stuff
  ########################################### 
  
      
	# 1. Create content page
	content_data = {
	  "sakai:pooled-content-file-name" => "Course Hub",
    "sakai:description" => "",
    "sakai:permissions" => "everyone",
    "sakai:copyright" => "creativecommons",
    "sakai:schemaversion" => 2,
    "mimeType" => "x-sakai/document",
    "structure0" => JSON.generate({
        "Course-Hub" => {
          "_title" => "Course Hub",
          "_order" => 0,
          "_ref" => "#{hub_content_id}",
          "_nonEditable" => false,
          "main" => {
              "_title" => "Course Hub",
              "_order" => 0,
              "_ref" => "#{hub_content_id}",
              "_nonEditable" => false
          }
        }
      })
	}
	
	response = prim_post("/system/pool/createfile", content_data)
	if @dry_run
	  json = {"_contentItem" => {"poolId" => "testing"}}
	else
    json = JSON.parse(response.body())	
  end
  content_id = json["_contentItem"]["poolId"]
  print "\n~~ 1. create hub content page #{content_id}: "
  print response
  
  # 2. post hub page docstructure
  print "\n~~ 2. post hub page docstructure: "
  response = post_json("/p/#{content_id}", JSON.generate(hub_docstructure_ugly))
  print response
  
  # 3. create version
  hub_docstructure.each do |id, data|
    content_data = {
      "sakai:pagecontent" => JSON.generate(data),
      "sling:resourceType" => "sakai/pagecontent"
    }  
    response = prim_post("/p/#{content_id}/#{id}.save.json", content_data)    
    print "\n~~ 3. post hub widget data for for #{id}: "
    print response
  end
  
  # 4. set permissions on content - logged in users (everyone)
  requests = [
    {"url"=>"/p/#{content_id}.members.html","method"=>"POST","parameters"=>{":viewer"=>"everyone",":viewer@Delete"=>"anonymous"}},
    {"url"=>"/p/#{content_id}.modifyAce.html","method"=>"POST","parameters"=>{"principalId"=>"everyone","privilege@jcr:read"=>"granted"}},
    {"url"=>"/p/#{content_id}.modifyAce.html","method"=>"POST","parameters"=>{"principalId"=>"anonymous","privilege@jcr:read"=>"denied"}}
  ]
  response = post_batch(requests)
  print "\n~~ 4. batch access: "
  print response
  
  # 5. link content to group
  requests = [
    {"url"=>"/p/#{content_id}.members.html","method"=>"POST","parameters"=>{":manager"=>"#{@groupid}-manager"}},
    {"url"=>"/p/#{content_id}.members.html","method"=>"POST","parameters"=>{":viewer"=>"#{@groupid}-member"}}
  ]
  response = post_batch(requests)
  print "\n~~ 5. batch link to group: "
  print response  
  
  # 6. remove creator as manager
  response = prim_post("/p/#{content_id}.members.json", {":manager@Delete" => "admin"})
  print "\n~~ 6. remove admin from manager list: "
  print response
  
  # 7. update group docstructure with new content item
  group_docstructure = get_json("/~#{@groupid}/docstructure.infinity.json")
  group_docstructure_structure0 = JSON.parse(group_docstructure["structure0"])
  group_docstructure_structure0["Course-Hub"] = {
    "_title" => "Course Hub",
    "_order" => -1,
    "_pid" => "#{content_id}",
    "_view" => JSON.generate(["everyone", "-member"]),
    "_edit" => JSON.generate(["-manager"]),
    "_nonEditable" => false
  }
  group_docstructure["structure0"] = JSON.generate(group_docstructure_structure0)
  response = post_json("/~#{@groupid}/docstructure", JSON.generate(group_docstructure))
  print "\n~~ 7. update group docstructure: "
  print response
  puts ""
  puts "DONE DONE DONE"
end


do_stuff
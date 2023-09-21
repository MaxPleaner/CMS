require 'sinatra'
require 'byebug'

set :public_folder, File.dirname(__FILE__) + "/grapesjs"

get '/' do
  send_file "result.html"
end

get '/editor' do
  send_file "grapesjs/demo.html"
end

post '/editor/store' do
  puts "STORING"
  request_body = JSON.parse(request.body.read)

  grapesjs_data = request_body.slice("data")
  File.open("storage.json", "w") { |f| f.write grapesjs_data.to_json }

  html_data = request_body["pagesHtml"]
  body, css = html_data[0].values_at("html", "css")
  html = build_html(body, css)
  File.open("result.html", "w") { |f| f.write html }
end

get '/editor/load' do
  puts "LOADING"
  send_file "storage.json"
end

def build_html(body, css)
  <<-TXT
  <!doctype html>
  <html lang='en'>
    <head>
      <style>
        #{css}
      </style>
    </head>
    #{body}
  </html>
  TXT
end



require 'sinatra'
require 'byebug'
require 'slim'
require "sinatra/reloader" if development?
require 'sinatra/flash'

enable :sessions
set :public_folder, File.dirname(__FILE__) + "/grapesjs"
SITES_DIR = "./sites"

# ---------------------------------------------
# Open the editor for a page
# Javascript calls the /store and /load endpoints
# ---------------------------------------------

get '/sites/:site/pages/:page/editor' do
  @site = alphanumeric(params[:site])
  @page = alphanumeric(params[:page])
  @published = published?(@site, @page)

  erb File.read(File.join(settings.public_folder, "demo.html.erb"))
end

# ---------------------------------------------
# Save editor data for a page
# ---------------------------------------------

post '/sites/:site/pages/:page/editor/store' do

  @site = alphanumeric(params[:site])
  @page = alphanumeric(params[:page])
  site_path = File.join(SITES_DIR, @site)
  return 404 if same_path?(site_path, SITES_DIR)

  pages_path = File.join(site_path, @page)
  return 404 if same_path?(pages_path, site_path)

  request_body = JSON.parse(request.body.read)

  grapesjs_data = request_body.slice("data")

  # Write JSON data
  storage_path = File.join(pages_path, "data.json")
  File.open(storage_path, "w") { |f| f.write grapesjs_data.to_json }

  # Write HTML
  html_data = request_body["pagesHtml"]
  body, css = html_data[0].values_at("html", "css")
  html = build_html(body, css)

  html_path = File.join(pages_path, "index.html")
  File.open(html_path, "w") { |f| f.write html }

  return 200
end

# ---------------------------------------------
# Load editor data for a page
# ---------------------------------------------

get '/sites/:site/pages/:page/editor/load' do
  @site = alphanumeric(params[:site])
  @page = alphanumeric(params[:page])

  site_path = File.join(SITES_DIR, @site)
  return 404 if same_path?(site_path, SITES_DIR)

  pages_path = File.join(site_path, @page)
  return 404 if same_path?(pages_path, site_path)

  storage_path = File.join(pages_path, "data.json")
  send_file storage_path
end

# ---------------------------------------------
# Publish a page
# ---------------------------------------------

get '/sites/:site/page/:page/publish' do
  # TODO
end

# ---------------------------------------------
# Unpublish a page
# ---------------------------------------------

get '/sites/:site/page/:page/unpublish' do
  # TODO
end

# ---------------------------------------------
# Revert changes since last publish
# ---------------------------------------------

get '/sites/:site/page/:page/revert' do
  # TODO
end

# ---------------------------------------------
# Get sites list
# ---------------------------------------------

get '/' do
  @sites = subfolders(SITES_DIR) || []
  slim :sites_manager
end

# ---------------------------------------------
# Clone site
# ---------------------------------------------

get '/sites/:site/clone' do
  # TODO
end

# ---------------------------------------------
# Clone page
# ---------------------------------------------

get '/sites/:site/pages/#{page}/clone' do
  # TODO
end

# ---------------------------------------------
# Delete site
# ---------------------------------------------

get '/sites/:site/delete' do
  # TODO
end

# ---------------------------------------------
# List of pages for a particular site
# ---------------------------------------------

get "/sites/:site" do
  @site = alphanumeric(params[:site])
  site_path = File.join(SITES_DIR, @site)
  return 404 if same_path?(site_path, SITES_DIR)

  @pages = subfolders(site_path) || []

  slim :pages_manager
end

# ---------------------------------------------
# Create a site
# ---------------------------------------------

post "/sites" do
  @site = alphanumeric(params[:site])
  site_path = File.join(SITES_DIR, @site)
  return 404 if same_path?(site_path, SITES_DIR)

  if File.exists?(site_path)
    flash[:message] = "Site already exists"
    redirect "/"
  end

  FileUtils.mkdir(site_path)

  redirect "/sites/#{@site}"
end


# ---------------------------------------------
# Create a page in a site
# ---------------------------------------------

post "/sites/:site/pages" do
  @site = alphanumeric(params[:site])
  @page = alphanumeric(params[:page])
  site_path = File.join(SITES_DIR, @site)
  return 404 if same_path?(site_path, SITES_DIR)

  pages_path = File.join(site_path, @page)
  return 404 if same_path?(pages_path, site_path)

  if File.exists?(pages_path)
    flash[:message] = "Page name is already taken"
    redirect "/sites/#{@site}"
  end

  FileUtils.mkdir(pages_path)

  redirect "/sites/#{@site}"
end

# ---------------------------------------------
# Delete a page in a site
# ---------------------------------------------

post "/sites/:site/pages/:page/delete" do
  @site = alphanumeric(params[:site])
  @page = alphanumeric(params[:page])
  site_path = File.join(SITES_DIR, @site)
  return 404 if same_path?(site_path, SITES_DIR)

  pages_path = File.join(site_path, @page)
  return 404 if same_path?(pages_path, site_path)

  unless File.exists?(pages_path)
    flash[:message] = "Page doesnt exist"
    redirect "/sites/#{@site}"
  end

  FileUtils.rm_rf(pages_path)

  redirect "/sites/#{@site}"
end

# ---------------------------------------------
# View a built page
# Keep this route handler last in the list
# since it's a big wildcard
# ---------------------------------------------

get '/:site/:page' do
  @site = alphanumeric(params[:site])
  @page = alphanumeric(params[:page])
  site_path = File.join(SITES_DIR, @site)
  return 404 if same_path?(site_path, SITES_DIR)

  pages_path = File.join(site_path, @page)
  return 404 if same_path?(pages_path, site_path)

  html_file = File.join(pages_path, "index.html")
  return 404 unless File.exists?(html_file)

  send_file html_file
end

# ---------------------------------------------
# Special handler to view the index page of a site
# ---------------------------------------------

get "/:site" do
  @site = alphanumeric(params[:site])
  @page = "index"
  site_path = File.join(SITES_DIR, @site)
  return 404 if same_path?(site_path, SITES_DIR)

  pages_path = File.join(site_path, @page)
  return 404 if same_path?(pages_path, site_path)

  html_file = File.join(pages_path, "index.html")
  return 404 unless File.exists?(html_file)

  send_file html_file
end

get "/:site/" do
  redirect "/#{params[:site]}"
end


# -------------------------------------------------
# Helper methods
# -------------------------------------------------

helpers do
  def published?(site, page)
    # TODO
  end
end

def same_path?(a, b)
  File.expand_path(a) == File.expand_path(b)
end

def safe_dir?(test_folder, parent_folder)
  File.expand_path(test_folder).start_with?(File.absolute_path(parent_folder))
end

def alphanumeric(string)
  string.gsub(/[^a-zA-Z0-9_-]/, '')
end

def subfolders(folder)
  Dir.entries(folder).select do |entry|
    File.directory?(File.join(folder, entry)) && ![ '.', '..' ].include?(entry)
  end
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



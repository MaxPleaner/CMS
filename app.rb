require 'sinatra'
require 'byebug'
require 'slim'
require "sinatra/reloader" if development?
require 'sinatra/flash'

# TODO: support layout functionality

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
  @activated = activated?(@site, @page)

  erb File.read(File.join(settings.public_folder, "demo.html.erb"))
end

# ---------------------------------------------
# Save editor data for a page
# ---------------------------------------------

post '/sites/:site/pages/:page/editor/store' do
  return 404 unless load_site_and_page(params)

  request_body = JSON.parse(request.body.read)

  grapesjs_data = request_body.slice("data")

  # Write JSON data
  storage_path = File.join(@page_path, "data-saved.json")
  File.open(storage_path, "w") { |f| f.write grapesjs_data.to_json }

  # Write HTML
  html_data = request_body["pagesHtml"]
  body, css = html_data[0].values_at("html", "css")
  html = build_html(body, css)

  html_path = File.join(@page_path, "index-saved.html")
  File.open(html_path, "w") { |f| f.write html }

  return 200
end

# ---------------------------------------------
# Load editor data for a page
# ---------------------------------------------

get '/sites/:site/pages/:page/editor/load' do
  return 404 unless load_site_and_page(params)

  storage_path = File.join(@page_path, "data-saved.json")
  send_file storage_path
end

# ---------------------------------------------
# Publish a page
# ---------------------------------------------

post '/sites/:site/page/:page/publish' do
  return 404 unless load_site_and_page(params)

  storage_path = File.join(@page_path, "data-saved.json")
  html_path = File.join(@page_path, "index-saved.html")
  return 404 unless [storage_path, html_path].all? { |path| File.exists?(path) }

  FileUtils.cp(storage_path, File.join(@page_path, "data.json"))
  FileUtils.cp(html_path, File.join(@page_path, "index.html"))

  return 200
end

# ---------------------------------------------
# Deactivate a page
# ---------------------------------------------

post '/sites/:site/page/:page/deactivate' do
  return 404 unless load_site_and_page(params)

  FileUtils.touch(File.join(@page_path, "deactivated"))

  redirect "/sites/#{@site}"
end

# ---------------------------------------------
# Reactivate a page
# ---------------------------------------------

post '/sites/:site/page/:page/reactivate' do
  return 404 unless load_site_and_page(params)

  file_path = File.join(@page_path, "deactivated")
  FileUtils.rm(file_path) if File.exists?(file_path)

  redirect "/sites/#{@site}"
end

# ---------------------------------------------
# Revert changes since last publish
# ---------------------------------------------

post '/sites/:site/page/:page/revert' do
  return 404 unless load_site_and_page(params)

  storage_path = File.join(@page_path, "data.json")
  html_path = File.join(@page_path, "index.html")
  return 404 unless [storage_path, html_path].all? { |path| File.exists?(path) }

  FileUtils.cp(storage_path, File.join(@page_path, "data-saved.json"))
  FileUtils.cp(html_path, File.join(@page_path, "index-saved.html"))

  redirect "/sites/#{@site}/pages/#{@page}/editor"
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

post '/sites/:site/clone' do
  return 404 unless load_site(params)

  new_site = alphanumeric(params[:new_name])
  new_path = File.join(SITES_DIR, new_site)

  if File.exists?(new_path)
    flash[:message] = "New site name is already taken."
    redirect "/"
  end

  FileUtils.cp_r(@site_path, new_path)

  redirect "/sites/#{new_site}"
end

# ---------------------------------------------
# Clone page
# ---------------------------------------------

post '/sites/:site/pages/:page/clone' do
  return 404 unless load_site_and_page(params)

  new_page = alphanumeric(params[:new_name])
  new_path = File.join(@site_path, new_page)

  if File.exists?(new_path)
    flash[:message] = "New page name is already taken."
    redirect "/sites/#{@site}"
  end

  FileUtils.cp_r(@page_path, new_path)

  redirect "/sites/#{@site}"
end

# ---------------------------------------------
# Delete site
# ---------------------------------------------

post '/sites/:site/delete' do
  return 404 unless load_site(params)

  FileUtils.rm_rf(@site_path)

  redirect "/"
end

# ---------------------------------------------
# List of pages for a particular site
# ---------------------------------------------

get "/sites/:site" do
  return 404 unless load_site(params)

  @pages = subfolders(@site_path) || []

  slim :pages_manager
end

# ---------------------------------------------
# Create a site
# ---------------------------------------------

post "/sites" do
  return 404 unless load_site(params)

  if File.exists?(@site_path)
    flash[:message] = "Site already exists"
    redirect "/"
  end

  FileUtils.mkdir(@site_path)

  redirect "/sites/#{@site}"
end


# ---------------------------------------------
# Create a page in a site
# ---------------------------------------------

post "/sites/:site/pages" do
  return 404 unless load_site_and_page(params)

  if File.exists?(@page_path)
    flash[:message] = "Page name is already taken"
    redirect "/sites/#{@site}"
  end

  FileUtils.mkdir(@page_path)

  redirect "/sites/#{@site}"
end

# ---------------------------------------------
# Delete a page in a site
# ---------------------------------------------

post "/sites/:site/pages/:page/delete" do
  return 404 unless load_site_and_page(params)

  unless File.exists?(@page_path)
    flash[:message] = "Page doesnt exist"
    redirect "/sites/#{@site}"
  end

  FileUtils.rm_rf(@page_path)

  redirect "/sites/#{@site}"
end

# ---------------------------------------------
# View a built page
# Keep this route handler last in the list
# since it's a big wildcard
# ---------------------------------------------

get '/:site/:page' do
  return 404 unless load_site_and_page(params)

  return 404 unless activated?(@site, @page)

  html_file = File.join(@page_path, "index.html")
  return 404 unless File.exists?(html_file)

  send_file html_file
end

# ---------------------------------------------
# Special handler to view the index page of a site
# ---------------------------------------------

get "/:site" do
  return 404 unless load_site(params)

  html_file = File.join(@site_path, "index", "index.html")
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
    site_path = File.join(SITES_DIR, site)
    pages_path = File.join(site_path, page)
    html_path = File.join(pages_path, "index.html")

    File.exists?(html_path)
  end

  def activated?(site, page)
    site_path = File.join(SITES_DIR, site)
    pages_path = File.join(site_path, page)

    !File.exists?(File.join(pages_path, "deactivated"))
  end
end

def load_site(params)
  @site = alphanumeric(params[:site])
  @site_path = File.join(SITES_DIR, @site)
  return false if same_path?(@site_path, SITES_DIR)

  true
end

def load_site_and_page(params)
  return false unless load_site(params)

  @page = alphanumeric(params[:page])
  return nil unless @page

  @page_path = File.join(@site_path, @page)
  return false if same_path?(@page_path, @site_path)

  true
end

def same_path?(a, b)
  File.expand_path(a) == File.expand_path(b)
end

def safe_dir?(test_folder, parent_folder)
  File.expand_path(test_folder).start_with?(File.absolute_path(parent_folder))
end

def alphanumeric(string)
  return unless string
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



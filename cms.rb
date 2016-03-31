require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

get '/' do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  erb :index
end

get '/new' do
  erb :new
end

post '/create' do
  filename = params[:filename].to_s

  if filename.length == 0
    session[:message] = 'You must enter a name.'
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, '')
    session[:message] = "#{params[:filename]} has been created."

    redirect '/'
  end
end

def load_file_content(file_path)
  content = File.read(file_path)

  case File.extname(file_path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    erb render_markdown(content)
  end
end

get '/:file' do
  file_path = File.join(data_path, params[:file])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:file]} does not exist."
    redirect '/'
  end
end

get '/:file/edit' do
  file_path = File.join(data_path, params[:file])

  if File.exist?(file_path)
    @file_content = File.read(file_path)

    erb :edit
  else
    session[:message] = "#{params[:file]} does not exist."
    redirect '/'
  end
end

post '/:file' do
  file_path = File.join(data_path, params[:file])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:file]} has been updated."
  redirect '/'
end

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  if params[:username] == 'admin' && params[:password] == 'password'
    session[:username] = params[:username]
    session[:message] = 'You are now signed in.'

    redirect '/'
  else
    session[:message] = 'Username or password is incorrect.'
    status 422

    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:message] = 'You have signed out.'

  redirect '/'
end

get '/' do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  erb :index
end

get '/new' do
  require_signed_in_user

  erb :new
end

post '/create' do
  require_signed_in_user

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
  require_signed_in_user

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
  require_signed_in_user

  file_path = File.join(data_path, params[:file])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:file]} has been updated."
  redirect '/'
end

post '/:file/destroy' do
  require_signed_in_user

  file_path = File.join(data_path, params[:file])

  File.delete(file_path)

  session[:message] = "#{params[:file]} has been deleted."
  redirect '/'
end

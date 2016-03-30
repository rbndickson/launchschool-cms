require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

root = File.expand_path('..', __FILE__)

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

get '/' do
  @files = Dir.glob(root + '/data/*').map do |path|
    File.basename(path)
  end

  erb :index
end

def load_file_content(file_path)
  content = File.read(file_path)

  case File.extname(file_path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    render_markdown(content)
  end
end

get '/:file' do
  file_path = root + "/data/#{params[:file]}"

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:file]} does not exist."
    redirect '/'
  end
end

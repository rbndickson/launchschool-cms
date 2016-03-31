ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../cms'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def test_index
    create_document 'about.md'
    create_document 'changes.txt'

    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
  end

  def test_viewing_text_file
    create_document 'history.txt', 'Yukihiro Matsumoto dreams up Ruby.'

    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, 'Yukihiro Matsumoto dreams up Ruby.'
  end

  def test_viewing_markdown_document
    create_document 'about.md', '#About Page'

    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']

    assert_includes last_response.body, '<h1>About Page</h1>'
  end

  def test_viewing_non_existant_document
    get '/xyz.txt'

    assert_equal 302, last_response.status
    assert_equal 'xyz.txt does not exist.', session[:message]
  end

  def test_editing_document_page
    create_document 'changes.txt'

    get '/changes.txt/edit'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Edit contents of changes.txt:'
    assert_includes last_response.body, 'Update File'
  end

  def test_saving_changes_to_document
    post '/changes.txt', content: 'Updated content'

    assert_equal 302, last_response.status
    assert_includes 'changes.txt has been updated.', session[:message]

    get '/changes.txt'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Updated content'
  end

  def test_view_new_document_form
    get '/new'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create_new_document
    post '/create', filename: 'test.txt'
    assert_equal 302, last_response.status
    assert_equal 'test.txt has been created.', session[:message]

    get '/'
    assert_includes last_response.body, 'test.txt'
  end

  def test_create_new_document_without_filename
    post '/create', filename: ''
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'You must enter a name.'
  end

  def test_deleting_document
    create_document('test.txt')

    post '/test.txt/destroy'
    assert_equal 302, last_response.status
    assert_includes 'test.txt has been deleted.', session[:message]

    get '/'
    refute_includes last_response.body, %q(href="/test.txt')
  end

  def test_signin_form
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post '/users/signin', username: 'admin', password: 'password'
    assert_equal 302, last_response.status
    assert_equal 'You are now signed in.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'Signed in as admin'
  end

  def test_signin_with_bad_credentials
    post '/users/signin', username: 'admin', password: 'incorrect_password'
    assert_equal 422, last_response.status
    assert_equal nil, session[:username]
    assert_includes last_response.body, 'Username or password is incorrect.'
  end

  def test_signout
    get '/', {}, { 'rack.session' => { username: 'admin' } }
    assert_includes last_response.body, 'Signed in as admin'

    post '/users/signout'
    get last_response['Location']

    assert_equal nil, session[:username]
    assert_includes last_response.body, 'You have signed out'
    assert_includes last_response.body, 'Sign In'
  end
end

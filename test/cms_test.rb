ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../cms'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']

    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
    assert_includes last_response.body, 'history.txt'
  end

  def test_file_view
    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, 'Yukihiro Matsumoto dreams up Ruby.'
  end

  def test_non_existant_document
    get '/xyz.txt'

    assert_equal 302, last_response.status
    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'xyz.txt does not exist'
  end

  def test_markdown_document
    get '/about.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']

    assert_includes last_response.body, '<h1>About Page</h1>'
  end

  def test_editing_document
    get '/changes.txt/edit'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Edit contents of changes.txt'
    assert_includes last_response.body, 'Update File'
  end

  def test_saving_changes_to_document
    post '/changes.txt', content: 'Updated content'

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_includes last_response.body, 'changes.txt has been updated'

    get '/changes.txt'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Updated content'
  end
end

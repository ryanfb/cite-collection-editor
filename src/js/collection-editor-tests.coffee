mock_access_token_params =
  access_token: 'nonsense'
  expires_in: 3600
  token_type: 'Bearer'

test "hello test", ->
  ok( 1 == 1, "Passed!" )

test "URN construction", ->
  equal( cite_urn('namespace','collection','row'), 'urn:cite:namespace:collection.row' )
  equal( cite_urn('namespace','collection','row','version'), 'urn:cite:namespace:collection.row.version' )

module "cookie functions"

test "values set by set_cookie should be readable by get_cookie", ->
  set_cookie 'cookie_test', 'test value', 60
  equal( get_cookie('cookie_test'), 'test value' )
  delete_cookie 'cookie_test'

test "values deleted by delete_cookie should return null", ->
  set_cookie 'delete_cookie_test', 'test value', 60
  delete_cookie 'delete_cookie_test'
  equal( get_cookie('delete_cookie_test'), null )

asyncTest "cookies set by set_cookie should expire", ->
  expect(2)
  set_cookie 'expire_cookie_test', 'test value', 1
  equal( get_cookie('expire_cookie_test'), 'test value' )
  setTimeout ->
    equal( get_cookie('expire_cookie_test'), null )
    start()
  , 1001

module "access token cookies",
  setup: ->
    delete_cookie 'access_token'
  teardown: ->
    delete_cookie 'access_token'
    $.mockjaxClear()

test "access token cookie should not be written for invalid access tokens", ->
  expect(2)
  equal( get_cookie('access_token'), null, 'cookie not set at test start' )
  $.mockjax
    url: 'https://www.googleapis.com/oauth2/v1/tokeninfo?*'
    contentType: 'text/json'
    responseText:
      error: "invalid_token"
    status: 400
  stop()
  set_access_token_cookie mock_access_token_params, ->
    equal( get_cookie('access_token'), null )
    start()

test "access token cookie should be written for valid access tokens", ->
  expect(2)
  equal( get_cookie('access_token'), null, 'cookie not set at test start' )
  $.mockjax
    url: 'https://www.googleapis.com/oauth2/v1/tokeninfo?*'
    contentType: 'text/json'
    responseText:
      audience: 'nonsense'
      user_id: 'nonsense'
      scope: 'nonsense'
      expires_in: 3600
    status: 200
  stop()
  set_access_token_cookie mock_access_token_params, ->
    equal( get_cookie('access_token'), mock_access_token_params['access_token'] )
    start()

module "author name"
  setup: ->
    set_cookie 'access_token', 'nonsense', 3600
    delete_cookie 'author_name'
    $('#Author').attr('value','')
  teardown: ->
    delete_cookie 'access_token'
    delete_cookie 'author_name'
    $('#Author').attr('value','')
    $.mockjaxClear()

test "set_author_name should pull from cookie when available", ->
  set_cookie 'author_name', 'Test User', 60
  set_author_name()
  equal( $('#Author').attr('value'), 'Test User' )

test "set_author_name with a successful AJAX call should set the cookie and populate the UI", ->
  expect(2)
  $.mockjax
    url: 'https://www.googleapis.com/oauth2/v1/userinfo?*'
    contentType: 'text/json'
    status: 200
    responseText:
      name: 'AJAX User'
  stop()
  set_author_name ->
    equal( get_cookie('author_name'), 'AJAX User' )
    equal( $('#Author').attr('value'), 'AJAX User' )
    start()

test "set_author_name with an unsuccessful AJAX call should do nothing", ->
  expect(2)
  $.mockjax
    url: 'https://www.googleapis.com/oauth2/v1/userinfo?*'
    contentType: 'text/json'
    responseText:
      error: "invalid_token"
    status: 400
  stop()
  set_author_name ->
    equal( get_cookie('author_name'), null )
    equal( $('#Author').attr('value'), '' )
    start()

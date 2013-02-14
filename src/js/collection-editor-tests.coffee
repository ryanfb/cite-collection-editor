$(document).ready ->
  mock_access_token_params =
    access_token: 'nonsense'
    expires_in: '3600'
    token_type: 'Bearer'

  test "hello test", ->
    ok( 1 == 1, "Passed!" )

  module "URN construction",
    setup: ->
      $('.container').append $('<select>').attr('id','collection_select').append($('<option>').attr('selected','selected').attr('value','nonsense'))
      $('.container').append $('<input>').attr('id','namespaceMapping').attr('value','namespace')
      $('.container').append $('<input>').attr('id','collection_name').attr('value','collection')
    teardown: ->
      $('#collection_select').remove()
      $('#namespaceMapping').remove()
      $('#collection_name').remove()
      $('#urn_object_prefix').remove()
      $.mockjaxClear()

  test "URN construction", ->
    equal( cite_urn('namespace','collection','row'), 'urn:cite:namespace:collection.row' )
    equal( cite_urn('namespace','collection','row','','version'), 'urn:cite:namespace:collection.row.version' )
    equal( cite_urn('namespace','collection','row','prefix_'), 'urn:cite:namespace:collection.prefix_row' )
    equal( cite_urn('namespace','collection','row','prefix_','version'), 'urn:cite:namespace:collection.prefix_row.version' )

  test "construct_latest_urn constructs expected URN for populated tables", ->
    expect(2)
    $.mockjax
      url: "#{FUSION_TABLES_URI}/query?*"
      contentType: 'text/json'
      responseText:
        rows: [["3"]]
    stop()
    construct_latest_urn (constructed_urn) ->
      equal( constructed_urn, 'urn:cite:namespace:collection.4.1', 'constructed URN has expected row and version' )
      start()
    $.mockjaxClear()
    $.mockjax
      url: "#{FUSION_TABLES_URI}/query?*"
      contentType: 'text/json'
      responseText:
        rows: [["4"]]
    stop()
    construct_latest_urn (constructed_urn) ->
      equal( constructed_urn, 'urn:cite:namespace:collection.5.1', 'constructed URN has expected row and version' )
      start()

  test "construct_latest_urn constructs expected URN for unpopulated tables", ->
    expect(1)
    $.mockjax
      url: "#{FUSION_TABLES_URI}/query?*"
      contentType: 'text/json'
      responseText:
        columns: []
    stop()
    construct_latest_urn (constructed_urn) ->
      equal( constructed_urn, 'urn:cite:namespace:collection.1.1', 'constructed URN has expected row and version' )
      start()

  test "construct_latest_urn constructs expected URN for populated tables with object prefix", ->
    $('.container').append $('<input>').attr('id','urn_object_prefix').attr('value','prefix_')
    expect(2)
    $.mockjax
      url: "#{FUSION_TABLES_URI}/query?*"
      contentType: 'text/json'
      responseText:
        rows: [["3"]]
    stop()
    construct_latest_urn (constructed_urn) ->
      equal( constructed_urn, 'urn:cite:namespace:collection.prefix_4.1', 'constructed URN has expected row and version' )
      start()
    $.mockjaxClear()
    $.mockjax
      url: "#{FUSION_TABLES_URI}/query?*"
      contentType: 'text/json'
      responseText:
        rows: [["4"]]
    stop()
    construct_latest_urn (constructed_urn) ->
      equal( constructed_urn, 'urn:cite:namespace:collection.prefix_5.1', 'constructed URN has expected row and version' )
      start()

  test "construct_latest_urn constructs expected URN for unpopulated tables with object prefix", ->
    $('.container').append $('<input>').attr('id','urn_object_prefix').attr('value','prefix_')
    expect(1)
    $.mockjax
      url: "#{FUSION_TABLES_URI}/query?*"
      contentType: 'text/json'
      responseText:
        columns: []
    stop()
    construct_latest_urn (constructed_urn) ->
      equal( constructed_urn, 'urn:cite:namespace:collection.prefix_1.1', 'constructed URN has expected row and version' )
      start()

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

  module "table access",
    setup: ->
      set_cookie 'access_token', 'nonsense', 3600
    teardown: ->
      delete_cookie 'access_token'
      $.mockjaxClear()
      $('.alert').remove()
  
  test "check_table_access should warn when table access isn't permitted", ->
    # TODO: form disable check
    expect(2)
    equal( $('.alert-error').length, 0, 'no errors at start' )
    $.mockjax
      url: "#{FUSION_TABLES_URI}/tables/*"
      contentType: 'text/json'
      responseText:
        error: "forbidden"
      status: 403
    stop()
    check_table_access 'nonsense', ->
      equal( $('.alert-error').length, 1, 'forbidden access inserts error message' )
      start()

  test "check_table_access should do nothing when table access is permitted", ->
    expect(2)
    equal( $('.alert-error').length, 0, 'no errors at start' )
    $.mockjax
      url: "#{FUSION_TABLES_URI}/tables/*"
      contentType: 'text/json'
      responseText:
        tableId: "nonsense"
      status: 200
    stop()
    check_table_access 'nonsense', ->
      equal( $('.alert-error').length, 0, 'no errors after access check' )
      start()

  module "timestamp",
    setup: ->
      $('.container').append $('<input>').attr('data-type','timestamp')
    teardown: ->
      $('input[data-type=timestamp]').remove()

  test "update_timestamp_inputs should update input[data-type=timestamp]", ->
    test_start_time = new Date()
    ok($('input[data-type=timestamp]').length, 'timestamp exists')
    ok(!$('input[data-type=timestamp]').val().length, 'timestamp has no value before update')
    update_timestamp_inputs()
    ok($('input[data-type=timestamp]').val().length, 'timestamp has value after update')
    constructed_date_value = new Date($('input[data-type=timestamp]').val())
    ok(constructed_date_value >= test_start_time, 'constructed date value is at or after test start time')
    ok(constructed_date_value <= (new Date()), 'constructed date value is before or at current time')

  module "author name",
    setup: ->
      set_cookie 'access_token', 'nonsense', 3600
      delete_cookie 'author_name'
      $('.container').append $('<input>').attr('data-type','authuser').attr('value','')
    teardown: ->
      delete_cookie 'access_token'
      delete_cookie 'author_name'
      $('input[data-type=authuser]').remove()
      $.mockjaxClear()

  test "set_author_name should pull from cookie when available", ->
    equal( $('input[data-type=authuser]').attr('value'), '', 'author empty at start')
    set_cookie 'author_name', 'Test User', 60
    set_author_name()
    equal( $('input[data-type=authuser]').attr('value'), 'Test User', 'author set')

  test "set_author_name with a successful AJAX call should set the cookie and populate the UI", ->
    expect(3)
    equal( $('input[data-type=authuser]').attr('value'), '', 'author empty at start')
    $.mockjax
      url: 'https://www.googleapis.com/oauth2/v1/userinfo?*'
      contentType: 'text/json'
      status: 200
      responseText:
        name: 'AJAX User'
        email: 'example@example.com'
    stop()
    set_author_name ->
      equal( get_cookie('author_name'), 'AJAX User <example@example.com>' )
      equal( $('input[data-type=authuser]').attr('value'), 'AJAX User <example@example.com>' )
      start()

  test "set_author_name with an unsuccessful AJAX call should do nothing", ->
    expect(3)
    equal( $('input[data-type=authuser]').attr('value'), '', 'author empty at start')
    $.mockjax
      url: 'https://www.googleapis.com/oauth2/v1/userinfo?*'
      contentType: 'text/json'
      responseText:
        error: "invalid_token"
      status: 400
    stop()
    set_author_name ->
      equal( get_cookie('author_name'), null )
      equal( $('input[data-type=authuser]').attr('value'), '' )
      start()

  module "filter url",
    setup: ->
      history.replaceState(null,'',window.location.href.replace("#{location.hash}",''))
    teardown: ->
      history.replaceState(null,'',window.location.href.replace("#{location.hash}",''))

  test "filter_url_params should filter off access_token, expires_in, and token_type by default, parse_query_string should parse hash parameters", ->
    clean_url = window.location.href.replace("#{location.hash}",'')
    equal( window.location.href, clean_url, "url is clean at test start" )
    history.replaceState(null,'',"#{window.location.href}##{$.param(mock_access_token_params)}")
    equal( window.location.href, "#{clean_url}##{$.param(mock_access_token_params)}", "url gets expected parameters at test start" )
    original_params = parse_query_string()
    deepEqual( original_params, mock_access_token_params, "parse_query_string parses hash parameters as expected" )
    filtered_params = filter_url_params(original_params)
    deepEqual( filtered_params, original_params, "filter_url_params returns original params" )
    equal( window.location.href, clean_url, "filter_url_params strips off expected params" )

  test "filter_url_params should filter off passed in parameters, parse_query_string should parse hash parameters", ->
    clean_url = window.location.href.replace("#{location.hash}",'')
    equal( window.location.href, clean_url, "url is clean at test start" )
    collection_param =
      collection: 'nonsense'
    history.replaceState(null,'',"#{window.location.href}##{$.param(collection_param)}")
    equal( window.location.href, "#{clean_url}##{$.param(collection_param)}", "url gets expected parameters at test start" )
    original_params = parse_query_string()
    deepEqual( original_params, collection_param, "parse_query_string parses hash parameters as expected" )
    filtered_params = filter_url_params(original_params,['collection'])
    deepEqual( filtered_params, original_params, "filter_url_params returns original params" )
    equal( window.location.href, clean_url, "filter_url_params strips off expected params" )

  module "config parameters",
    teardown: ->
      delete window.cite_collection_editor_config
      delete google_oauth_parameters_for_fusion_tables.client_id

  test "merge_config_parameters should use window.cite_collection_editor_config to overwrite default config values", ->
    original_config_parameters = merge_config_parameters()
    deepEqual(original_config_parameters, default_cite_collection_editor_config, 'original parameters equal default parameters')
    equal(google_oauth_parameters_for_fusion_tables['client_id'], default_cite_collection_editor_config['google_client_id'], 'OAuth parameters equal default parameters')
    window.cite_collection_editor_config = {}
    window.cite_collection_editor_config['google_client_id'] = 'nonsense'
    window.cite_collection_editor_config['capabilities_url'] = 'nonsense.xml'
    modified_config_parameters = merge_config_parameters()
    equal(modified_config_parameters['google_client_id'],'nonsense','google_client_id key overwritten')
    equal(modified_config_parameters['capabilities_url'],'nonsense.xml','capabilities_url key overwritten')
    equal(google_oauth_parameters_for_fusion_tables['client_id'], 'nonsense', 'OAuth parameters equal modified parameters')

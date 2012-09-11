FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v1'

google_oauth_parameters_for_fusion_tables =
  response_type: 'token'
  client_id: '891199912324.apps.googleusercontent.com'
  redirect_uri: window.location.href.replace("#{location.hash}",'')
  scope: 'https://www.googleapis.com/auth/fusiontables https://www.googleapis.com/auth/userinfo.profile'
  approval_prompt: 'auto'

google_oauth_url =
  "https://accounts.google.com/o/oauth2/auth?#{$.param(google_oauth_parameters_for_fusion_tables)}"

cite_urn = (namespace, collection, row, version) ->
  urn = "urn:cite:#{namespace}:#{collection}.#{row}"
  if arguments.length == 4
    urn += ".#{version}"
  return urn

disable_collection_form = ->
  $('#collection_form').children().prop('disabled',true)

build_input_for_valuelist = (valuelist) ->
  select = $('<select>').attr('style','display:block')
  values = $(valuelist).find('value')
  select.append $('<option>').append($(value).text()) for value in values
  return select

update_timestamp_inputs = ->
  $('#Date').attr('value',(new Date).toISOString())

build_input_for_property = (property) ->
  input = switch $(property).attr('type')
    when 'markdown'
      pagedown_container = $('<div>').attr('class','pagedown_container')
      pagedown_suffix = $('<input>').attr('type','hidden').attr('class','pagedown_suffix').attr('value',$(property).attr('name'))
      pagedown_panel = $('<div>').attr('class','wmd-panel')
      pagedown_panel.append $('<div>').attr('id',"wmd-button-bar-#{$(property).attr('name')}")
      pagedown_panel.append $('<textarea>').attr('class','wmd-input').attr('id',"wmd-input-#{$(property).attr('name')}")
      pagedown_preview = $('<div>').attr('class','wmd-panel wmd-preview').attr('id',"wmd-preview-#{$(property).attr('name')}")
      pagedown_container.append pagedown_suffix
      pagedown_container.append pagedown_panel
      pagedown_container.append $('<label>').append('Preview:')
      pagedown_container.append pagedown_preview
      pagedown_container
    when 'string'
      if $(property).find('valueList').length > 0
        build_input_for_valuelist $(property).find('valueList')[0]
      else
        $('<input>').attr('style','width:100%;display:block')
    when 'citeurn', 'citeimg'
      # for the special case of the "URN" field, we want to construct the value
      if $(property).attr('name') == 'URN'
        $('<input>').attr('style','width:100%').prop('disabled',true)
      else
        $('<input>').attr('style','width:100%')
    when 'datetime'
      $('<input>').attr('style','width:50%').attr('type','datetime').prop('disabled',true).attr('style','display:block')
    else
      console.log 'Error: unknown type'
      $('<input>')
  $(input).attr('id',$(property).attr('name'))

add_property_to_form = (property, form) ->
  form.append $('<br>')
  form.append $('<label>').attr('for',$(property).attr('name')).append($(property).attr('label') + ':').attr('style','display:inline')
  form.append $('<div>').attr('id',"#{$(property).attr('name')}-clippy")
  form.append build_input_for_property property

fusion_tables_query = (query, callback) ->
  console.log "Query: #{query}"
  switch query.split(' ')[0]
    when 'INSERT'
      $.ajax "#{FUSION_TABLES_URI}/query?access_token=#{get_cookie 'access_token'}",
        type: 'POST'
        dataType: 'json'
        crossDomain: true
        data:
          sql: query
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
        success: (data) ->
          console.log data
          if callback?
            callback(data)
    when 'SELECT'
      $.ajax "#{FUSION_TABLES_URI}/query?sql=#{query}&access_token=#{get_cookie 'access_token'}",
        type: 'GET'
        cache: false
        dataType: 'json'
        crossDomain: true
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
        success: (data) ->
          console.log data
          if callback?
            callback(data)
  
construct_latest_urn = (callback) ->
  collection = $('#collection_select').val()
  fusion_tables_query "SELECT ROWID FROM #{collection}", (data) =>
    console.log data
    last_available = if data['rows']? then data['rows'].length + 1 else 1
    latest_urn = cite_urn($('#namespaceMapping').attr('value'),$('#collection_name').attr('value'),last_available)
    console.log "Latest URN: #{latest_urn}"
    callback(latest_urn)

save_collection_form = ->
  collection = $('#collection_select').val()
  localStorage[collection] = true
  for child in $('#collection_form').children()
    if $(child).attr('id') && !$(child).prop('disabled') && ($(child).attr('type') != 'hidden')
      localStorage["#{collection}:#{$(child).attr('id')}"] = $(child).val()
  $('#collection_form').after $('<div>').attr('class','alert alert-success').attr('id','save_success').append('Saved.')
  $('#save_success').fadeOut 1800, ->
    $(this).remove()

# wrap values in single quotes and backslash-escape single-quotes
fusion_tables_escape = (value) ->
  "'#{value.replace(/'/g,"\\\'")}'"

submit_collection_form = ->
  disable_collection_form()
  collection = $('#collection_select').val()
  column_names = []
  row_values = []
  construct_latest_urn (urn) =>
    $('#URN').attr('value',urn)
    update_timestamp_inputs()
    for child in $('#collection_form').children()
      if $(child).attr('id') && ($(child).attr('type') != 'hidden')
        column_names.push fusion_tables_escape($(child).attr('id'))
        row_values.push fusion_tables_escape($(child).val())
    fusion_tables_query "INSERT INTO #{collection} (#{column_names.join(', ')}) VALUES (#{row_values.join(', ')})", (data) ->
      clear_collection_form()
      $('#collection_form').after $('<div>').attr('class','alert alert-success').attr('id','submit_success').append('Submitted.')
      $('#submit_success').delay(1800).fadeOut 1800, ->
        $(this).remove()

load_collection_form = ->
  collection = $('#collection_select').val()
  if localStorage[collection]
    for child in $('#collection_form').children()
      if $(child).attr('id') && localStorage["#{collection}:#{$(child).attr('id')}"]?
        $(child).val(localStorage["#{collection}:#{$(child).attr('id')}"])

clear_collection_form = ->
  collection = $('#collection_select').val()
  localStorage.removeItem(collection)
  for child in $('#collection_form').children()
    if $(child).attr('id')
      localStorage.removeItem("#{collection}:#{$(child).attr('id')}")
  $('#collection_select').change()

build_collection_form = (collection) ->
  form = $('<form>').attr('id','collection_form')
  
  form.append $('<input>').attr('type','hidden').attr('id','namespaceMapping').attr('value',$(collection).find('namespaceMapping').attr('abbr'))
  form.append $('<input>').attr('type','hidden').attr('id','collection_name').attr('value',$(collection).attr('name'))

  properties = $(collection).find('citeProperty')
  add_property_to_form(property,form) for property in properties

  submit_button = $('<input>').attr('type','button').attr('value','Submit').attr('class','btn btn-primary')
  submit_button.bind 'click', (event) =>
    submit_collection_form()
  save_button = $('<input>').attr('type','button').attr('value','Save').attr('class','btn')
  save_button.bind 'click', (event) =>
    save_collection_form()
  clear_button = $('<input>').attr('type','button').attr('value','Clear').attr('class','btn btn-danger').attr('style','float:right')
  clear_button.bind 'click', (event) =>
    if confirm('Are you sure you wish to clear the form? This action cannot be undone.')
      clear_collection_form()

  form.append $('<br>')
  form.append submit_button
  form.append '&nbsp;&nbsp;'
  form.append save_button
  form.append clear_button

  # test table access
  if get_cookie 'access_token'
    $.ajax "#{FUSION_TABLES_URI}/tables/#{$(collection).attr('class')}?access_token=#{get_cookie 'access_token'}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "AJAX Error: #{textStatus}"
        $('h1').after $('<div>').attr('class','alert alert-error').attr('id','collection_access_error').append('You do not have permission to access this collection.')
        disable_collection_form()
      success: (data) ->
        console.log data

  $('.container').append form

  set_author_name()
  construct_latest_urn (urn) ->
    $('#URN').attr('value',urn)
  update_timestamp_inputs()

  converter = new Markdown.Converter()
  for suffix in $(".pagedown_suffix")
    console.log "Running Markdown editor for: #{$(suffix).val()}"
    editor = new Markdown.Editor(converter,"-#{$(suffix).val()}")
    editor.run()

  if swfobject.hasFlashPlayerVersion('9')
    clippy $(property).attr('name') for property in properties

set_author_name = ->
  if get_cookie 'author_name'
    $('#Author').attr('value',get_cookie 'author_name')
  else if get_cookie 'access_token'
    $.ajax "https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{get_cookie 'access_token'}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "AJAX Error: #{textStatus}"
        # $('h1').after $('<div>').attr('class','alert alert-warning').append('Error retrieving profile info.')
      success: (data) ->
        set_cookie('author_name',data['name'],3600)
        $('#Author').attr('value',data['name'])

parse_query_string = (query_string) ->
  params = {}
  if query_string.length > 0
    regex = /([^&=]+)=([^&]*)/g
    while m = regex.exec(query_string)
      params[decodeURIComponent(m[1])] = decodeURIComponent(m[2])
  return params

filter_url_params = (params) ->
  rewritten_params = []
  for key, value of params
    unless _.include(['access_token','expires_in','token_type'],key)
      rewritten_params.push "#{key}=#{value}"
  if rewritten_params.length > 0
    hash_string = "##{rewritten_params.join('&')}"
  else
    hash_string = ''
  history.replaceState(null,'',window.location.href.replace("#{location.hash}",hash_string))
  return params

set_cookie = (key, value, expires_in) ->
  cookie_expires = new Date
  cookie_expires.setTime(cookie_expires.getTime() + expires_in * 1000)
  cookie = "#{key}=#{value}; "
  cookie += "expires=#{cookie_expires.toGMTString()}; "
  cookie += "path=#{window.location.pathname.substring(0,window.location.pathname.lastIndexOf('/')+1)}"
  document.cookie = cookie

get_cookie = (key) ->
  key += "="
  for cookie_fragment in document.cookie.split(';')
    cookie_fragment = cookie_fragment.replace(/^\s+/, '')
    return cookie_fragment.substring(key.length, cookie_fragment.length) if cookie_fragment.indexOf(key) == 0
  return null

set_access_token_cookie = (params) ->
  if params['access_token']?
    # validate the token per https://developers.google.com/accounts/docs/OAuth2UserAgent#validatetoken
    $.ajax "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=#{params['access_token']}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "Access Token Validation Error: #{textStatus}"
      success: (data) ->
        set_cookie('access_token',params['access_token'],params['expires_in'])
        $('#oauth_access_warning').remove()

clippy = (id) ->
  console.log "Clippy: #{id}"
  flashvars =
    id: "#{id}"
  flashparams =
    quality: 'high'
    allowscriptaccess: 'always'
    scale: 'noscale'
  objectattrs =
    classid: 'clsid:d27cdb6e-ae6d-11cf-96b8-444553540000'
    style: "padding-left:5px;padding-top:5px;background-position:5px 5px;background-repeat:no-repeat;background-image:url('vendor/clippy/button_up.png')"
  swfobject.embedSWF("vendor/clippy/clippy.swf", "#{id}-clippy", "110", "14", "9", false, flashvars, flashparams, objectattrs)

$(document).ready ->
  set_access_token_cookie filter_url_params(parse_query_string(location.hash.substring(1)))
  
  $.ajax 'capabilities/testedit-capabilities.xml',
    type: 'GET'
    dataType: 'xml'
    error: (jqXHR, textStatus, errorThrown) ->
      console.log "AJAX Error: #{textStatus}"
    success: (data) ->
      collections = $(data).find('citeCollection')
      select = $('<select>')
      select.append $('<option>').attr('value',$(collection).attr('class')).append($(collection).attr('description')) for collection in collections
      $(select).attr('id','collection_select')
      $(select).attr('style','width:100%')
      $('.container').append select
      $('#collection_select').chosen()
      $('#collection_select').bind 'change', (event) =>
        $('#collection_form').remove()
        $('.alert').remove()
        selected = $('#collection_select option:selected')[0]
        selected_collection = $(data).find("citeCollection[class=#{$(selected).attr('value')}]")[0]
        build_collection_form selected_collection
        load_collection_form()
        unless get_cookie 'access_token'
          $('h1').after $('<div>').attr('class','alert alert-warning').attr('id','oauth_access_warning').append('You have not authorized this application to access your Google Fusion Tables. ')
          $('#oauth_access_warning').append $('<a>').attr('href',google_oauth_url).append('Click here to authorize.')
          disable_collection_form()
      $('#collection_select').change()

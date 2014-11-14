FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v1'

default_cite_collection_editor_config =
  google_client_id: '891199912324.apps.googleusercontent.com'
  capabilities_url: 'capabilities/testedit-capabilities.xml'

google_oauth_parameters_for_fusion_tables =
  response_type: 'token'
  redirect_uri: window.location.href.replace("#{location.hash}",'')
  scope: 'https://www.googleapis.com/auth/fusiontables https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email'
  approval_prompt: 'auto'

google_oauth_url = ->
  "https://accounts.google.com/o/oauth2/auth?#{$.param(google_oauth_parameters_for_fusion_tables)}"

# construct a CITE URN with optional version
cite_urn = (namespace, collection, row, prefix = '', version) ->
  urn = "urn:cite:#{namespace}:#{collection}.#{prefix}#{row}"
  if arguments.length == 5
    urn += ".#{version}"
  return urn

pagedown_editors = {}

disable_collection_form = ->
  $('#collection_form').children().prop('disabled',true)
  $('.wmd-input').prop('disabled',true)
  $('.btn').prop('disabled',true)

build_input_for_valuelist = (valuelist) ->
  select = $('<select>').attr('style','display:block')
  values = $(valuelist).find('value')
  select.append $('<option>').append($(value).text()) for value in values
  return select

update_timestamp_inputs = ->
  $('input[data-type=timestamp]').attr('value',(new Date).toISOString())

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
        $('<textarea>').attr('style','width:100%').attr('rows','1')
    when 'datetime', 'authuser'
      $('<input>').attr('style','width:100%;display:block')
    when 'citeurn', 'citeimg', 'ctsurn'
      # for the special case of the "URN" field, we want to construct the value
      if $(property).attr('name') == $(property).parent().attr('canonicalId')
        $('<input>').attr('style','width:100%').attr('data-urn','true').prop('disabled',true)
      else
        $('<input>').attr('style','width:100%')
    when 'timestamp'
      $('<input>').attr('style','width:50%').attr('type','timestamp').prop('disabled',true).attr('style','display:block')
    else
      console.log 'Error: unknown type'
      $('<input>')
  $(input).attr('id',$(property).attr('name'))
  $(input).attr('data-type',$(property).attr('type'))

add_property_to_form = (property, form) ->
  form.append $('<br>')
  form.append $('<label>').attr('for',$(property).attr('name')).append($(property).attr('label') + ':').attr('style','display:inline')
  if $(property).attr('type') == 'markdown'
    form.append $('<div>').attr('id',"wmd-input-#{$(property).attr('name')}-clippy")
  else
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
          $('#collection_form').after $('<div>').attr('class','alert alert-error').attr('id','submit_error').append("Error submitting data: #{textStatus}")
          scroll_to_bottom()
          $('#submit_error').delay(1800).fadeOut 1800, ->
            $(this).remove()
            $('#collection_select').change()
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

# getter for form inputs because we need a special case for markdown
get_value_for_form_input = (element) ->
  if $(element).attr('class') == 'pagedown_container'
    $(element).find('.wmd-input').val()
  else
    $(element).val()

# construct the latest URN - because this is asynchronous, it
# takes a callback function which gets passed the resulting URN
construct_latest_urn = (callback) ->
  collection = $('#collection_select').val()
  urn_input = $('input[data-urn=true]')
  urn_query_value = parse_query_string()[urn_input.attr('id')]
  if urn_query_value?
    cite_urn_prefix = cite_urn($('#namespaceMapping').attr('value'),$('#collection_name').attr('value'),'\\d+',$('#urn_object_prefix').attr('value'))
    urn_prefix_regex = new RegExp("^(#{cite_urn_prefix.replace('.','\\.')})(\\.\\d+)?$")
    console.log urn_prefix_regex
    urn_prefix_matches = urn_prefix_regex.exec(urn_query_value)
    console.log urn_prefix_matches
    if urn_prefix_matches?
      fusion_tables_query "SELECT COUNT() FROM #{collection} WHERE '#{urn_input.attr('id')}' STARTS WITH '#{urn_prefix_matches[1]}.'", (data) =>
        console.log data
        if data['rows']?
          existing_versions = parseInt(data['rows'][0][0])
          latest_urn = "#{urn_prefix_matches[1]}.#{existing_versions + 1}"
          console.log "Latest URN: #{latest_urn}"
          loaded_urn = urn_prefix_matches[1]
          if (urn_prefix_matches[2]?) && (parseInt(urn_prefix_matches[2].substring(1)) <= existing_versions)
            loaded_urn += urn_prefix_matches[2]
          else
            loaded_urn += ".#{existing_versions}"
          load_collection_form_from_urn(loaded_urn)
          callback(latest_urn)
        else # invalid URN passed in, strip and retry
          console.log "No existing versions for passed URN, constructing latest URN from scratch"
          filter_url_params(parse_query_string(),[urn_input.attr('id')])
          construct_latest_urn(callback)
    else # invalid URN passed in, strip and retry
      console.log "Passed URN invalid, constructing latest URN from scratch"
      filter_url_params(parse_query_string(),[urn_input.attr('id')])
      construct_latest_urn(callback)
  else
    fusion_tables_query "SELECT COUNT() FROM #{collection}", (data) =>
      console.log data
      last_available = if data['rows']? then parseInt(data['rows'][0][0]) + 1 else 1
      latest_urn = cite_urn($('#namespaceMapping').attr('value'),$('#collection_name').attr('value'),last_available,$('#urn_object_prefix').attr('value'),1)
      console.log "Latest URN: #{latest_urn}"
      callback(latest_urn)

scroll_to_bottom = ->
  $('html, body').animate({scrollTop: $(document).height()-$(window).height()},600,'linear')

# save collection form values to localStorage
@save_collection_form = save_collection_form = ->
  collection = $('#collection_select').val()
  localStorage[collection] = true
  for child in $('#collection_form').children()
    if $(child).attr('id') && !$(child).prop('disabled') && ($(child).attr('type') != 'hidden')
      localStorage["#{collection}:#{$(child).attr('id')}"] = get_value_for_form_input(child)
    else if ($(child).attr('id') == $('input[data-urn=true]').attr('id')) && (parse_query_string()[$(child).attr('id')]?)
      # save the passed URN
      localStorage["#{collection}:#{$(child).attr('id')}"] = parse_query_string()[$(child).attr('id')]
  $('#collection_form').after $('<div>').attr('class','alert alert-success').attr('id','save_success').append('Saved.')
  scroll_to_bottom()
  $('#save_success').fadeOut 1800, ->
    $(this).remove()

# wrap values in single quotes and backslash-escape single-quotes
fusion_tables_escape = (value) ->
  "'#{value.replace(/'/g,"\\\'")}'"

# submit the form to Fusion Tables
submit_collection_form = ->
  disable_collection_form()
  save_collection_form()
  collection = $('#collection_select').val()
  column_names = []
  row_values = []
  # the main body of the submission is in an anonymous callback function that gets the URN,
  # this is so we hopefully have the latest URN possible
  construct_latest_urn (urn) =>
    $('input[data-urn=true]').attr('value',urn)
    update_timestamp_inputs()
    for child in $('#collection_form').children()
      if $(child).attr('id') && ($(child).attr('type') != 'hidden') && !$(child).attr('id').match(/-clippy$/) && ($(child).attr('id') != 'submit_button')
        column_names.push fusion_tables_escape($(child).attr('id'))
        row_values.push fusion_tables_escape(get_value_for_form_input(child))
    fusion_tables_query "INSERT INTO #{collection} (#{column_names.join(', ')}) VALUES (#{row_values.join(', ')})", (data) ->
      filter_url_params(parse_query_string(),[$('input[data-urn=true]').attr('id')])
      clear_collection_form()
      $('#collection_form').after $('<div>').attr('class','alert alert-success').attr('id','submit_success').append('Submitted.')
      scroll_to_bottom()
      $('#submit_success').delay(1800).fadeOut 1800, ->
        $(this).remove()

# populate collection form values from hash parameters or localStorage if set
load_collection_form = ->
  collection = $('#collection_select').val()
  for child in $('#collection_form').children()
    if $(child).attr('id')?
      if (parse_query_string()[$(child).attr('id')]?) && ($(child).attr('id') != $('input[data-urn=true]').attr('id'))
        $(child).val(parse_query_string()[$(child).attr('id')])
        filter_url_params(parse_query_string(),[$(child).attr('id')])
      else if localStorage["#{collection}:#{$(child).attr('id')}"]?
        if $(child).attr('class') == 'pagedown_container'
          $(child).find('.wmd-input').val(localStorage["#{collection}:#{$(child).attr('id')}"])
        else if $(child).attr('id') == $('input[data-urn=true]').attr('id')
          # push URN into hash parameters
          history.replaceState(null,'',window.location.href.replace("#{location.hash}","#{location.hash}&#{$(child).attr('id')}=#{localStorage["#{collection}:#{$(child).attr('id')}"]}"))
        else
          $(child).val(localStorage["#{collection}:#{$(child).attr('id')}"])

# populate collection form values from a given URN
load_collection_form_from_urn = (loaded_urn) ->
  collection = $('#collection_select').val()
  # don't clobber saved/loaded data
  unless localStorage["#{collection}:#{$('input[data-urn=true]').attr('id')}"]?
    console.log "Loading data from: #{loaded_urn}"
    fusion_tables_query "SELECT * FROM #{collection} WHERE '#{$('input[data-urn=true]').attr('id')}' = '#{loaded_urn}'", (data) ->
      console.log "Existing data:"
      console.log data
      for header, i in data['columns']
        unless $("##{header}").prop('disabled')
          console.log "Setting #{header} to #{data['rows'][0][i]}"
          if $("##{header}").attr('class') == 'pagedown_container'
            $("#wmd-input-#{header}").val(data['rows'][0][i])
            if pagedown_editors[header]?
              pagedown_editors[header].refreshPreview()
          else
            $("##{header}").val(data['rows'][0][i])

# remove form values from localStorage and reset the form
clear_collection_form = ->
  collection = $('#collection_select').val()
  localStorage.removeItem(collection)
  for child in $('#collection_form').children()
    if $(child).attr('id')
      localStorage.removeItem("#{collection}:#{$(child).attr('id')}")
  $('#collection_select').change()

check_table_access = (table_id, callback) ->
  # test table access
  if get_cookie 'access_token'
    $.ajax "#{FUSION_TABLES_URI}/tables/#{table_id}?access_token=#{get_cookie 'access_token'}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "AJAX Error: #{textStatus}"
        $('.container > h1').after $('<div>').attr('class','alert alert-error').attr('id','collection_access_error').append('You do not have permission to access this collection.')
        disable_collection_form()
      success: (data) ->
        console.log data
      complete: (jqXHR, textStatus) ->
        callback() if callback?

# top-level function for building the collection form
build_collection_form = (collection) ->
  form = $('<form>').attr('id','collection_form')
  
  form.append $('<input>').attr('type','hidden').attr('id','namespaceMapping').attr('value',$(collection).find('namespaceMapping').attr('abbr'))
  form.append $('<input>').attr('type','hidden').attr('id','collection_name').attr('value',$(collection).attr('name'))
  form.append $('<input>').attr('type','hidden').attr('id','urn_object_prefix').attr('value',$(collection).find("citeProperty[name='#{$(collection).attr('canonicalId')}']").attr('objectPrefix'))

  properties = $(collection).find('citeProperty')
  add_property_to_form(property,form) for property in properties

  submit_button = $('<input>').attr('type','button').attr('value','Submit').attr('class','btn btn-primary').attr('id','submit_button')
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

  $('.container').append form
  check_table_access $(collection).attr('class')

  # update various inputs after we've actually put the form in the DOM
  load_collection_form()
  set_author_name()
  construct_latest_urn (urn) ->
    $('input[data-urn=true]').attr('value',urn)
  update_timestamp_inputs()

  # create the Markdown/Pagedown preview after we've put the form in the DOM
  converter = new Markdown.Converter()
  for suffix in $(".pagedown_suffix")
    console.log "Running Markdown editor for: #{$(suffix).val()}"
    pagedown_editors[$(suffix).val()] = new Markdown.Editor(converter,"-#{$(suffix).val()}")
    pagedown_editors[$(suffix).val()].run()

  # if we have Flash, put clippy helpers on all the inputs
  if swfobject.hasFlashPlayerVersion('9')
    for property in properties
      if $(property).attr('type') == 'markdown'
        clippy "wmd-input-#{$(property).attr('name')}"
      else
        clippy $(property).attr('name')

  # set textareas to autosize
  $('textarea').autosize()

  # set an OAuth expiration callback
  if get_cookie 'access_token_expires_at'
    authorization_expires_in = parseInt(get_cookie('access_token_expires_at')) - Date.now()
    console.log "Disabling submit in #{authorization_expires_in}ms"
    setTimeout ->
      disable_submit()
    , authorization_expires_in

# set the author name using Google profile information
set_author_name = (callback) ->
  if get_cookie 'author_name'
    $('input[data-type=authuser]').attr('value',get_cookie 'author_name')
    $('input[data-type=authuser]').prop('disabled',true)
  else if get_cookie 'access_token'
    $.ajax "https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{get_cookie 'access_token'}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "AJAX Error: #{textStatus}"
        # $('.container > h1').after $('<div>').attr('class','alert alert-warning').append('Error retrieving profile info.')
      success: (data) ->
        set_cookie('author_name',"#{data['name']} <#{data['email']}>",3600)
        $('input[data-type=authuser]').attr('value',get_cookie('author_name'))
        $('input[data-type=authuser]').prop('disabled',true)
      complete: (jqXHR, textStatus) ->
        callback() if callback?

# parse URL hash parameters into an associative array object
parse_query_string = (query_string) ->
  query_string ?= location.hash.substring(1)
  params = {}
  if query_string.length > 0
    regex = /([^&=]+)=([^&]*)/g
    while m = regex.exec(query_string)
      params[decodeURIComponent(m[1])] = decodeURIComponent(m[2])
  return params

# filter URL parameters out of the window URL using replaceState 
# returns the original parameters
filter_url_params = (params, filtered_params) ->
  rewritten_params = []
  filtered_params ?= ['access_token','expires_in','token_type']
  for key, value of params
    unless _.include(filtered_params,key)
      rewritten_params.push "#{key}=#{value}"
  if rewritten_params.length > 0
    hash_string = "##{rewritten_params.join('&')}"
  else
    hash_string = ''
  history.replaceState(null,'',window.location.href.replace("#{location.hash}",hash_string))
  return params

expires_in_to_date = (expires_in) ->
  cookie_expires = new Date
  cookie_expires.setTime(cookie_expires.getTime() + expires_in * 1000)
  return cookie_expires

set_cookie = (key, value, expires_in) ->
  cookie = "#{key}=#{value}; "
  cookie += "expires=#{expires_in_to_date(expires_in).toUTCString()}; "
  cookie += "path=#{window.location.pathname.substring(0,window.location.pathname.lastIndexOf('/')+1)}"
  document.cookie = cookie

delete_cookie = (key) ->
  set_cookie key, null, -1

get_cookie = (key) ->
  key += "="
  for cookie_fragment in document.cookie.split(';')
    cookie_fragment = cookie_fragment.replace(/^\s+/, '')
    return cookie_fragment.substring(key.length, cookie_fragment.length) if cookie_fragment.indexOf(key) == 0
  return null

# write a Google OAuth access token into a cached cookie that should expire when the access token does
set_access_token_cookie = (params, callback) ->
  if params['state']?
    console.log "Replacing hash with state: #{params['state']}"
    history.replaceState(null,'',window.location.href.replace("#{location.hash}","##{params['state']}"))
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
        set_cookie('access_token_expires_at',expires_in_to_date(params['expires_in']).getTime(),params['expires_in'])
        $('#collection_select').change()
      complete: (jqXHR, textStatus) ->
        callback() if callback?

# construct a clippy element to replace the given placeholder id
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

# use hash parameters to set the selected collection
set_selected_collection_from_hash_parameters = ->
  if parse_query_string()['collection']?
    $("option[data-name=#{parse_query_string()['collection']}]").attr('selected','selected')
    $('#collection_select').change()

# push the selected collection into history with the collection as a hash parameter
push_selected_collection = ->
  selected = $('#collection_select option:selected')[0]
  new_hash = "#collection=#{$(selected).attr('data-name')}"
  filter_url_params(parse_query_string(),['collection'])
  new_url = if location.hash.length > 0
    window.location.href.replace("#{location.hash}","#{new_hash}&#{location.hash.substring(1)}")
  else
    window.location.href + new_hash
  history.pushState(null,$(selected).text(),new_url)

# disable the submit button with an informative dialogue if the cookie expires while editing
disable_submit = ->
  $('#submit_button').prop('disabled',true)
  $('#submit_button').before $('<div>').attr('class','alert alert-warning').attr('id','oauth_expiration_warning').append('Your Google Fusion Tables authorization has expired. ')
  $('#oauth_expiration_warning').append $('<a>').attr('href',google_oauth_url()).append('Click here to save your work and re-authorize.').attr('onclick','save_collection_form()')
  $('#oauth_expiration_warning').append(' You will be able to submit your work upon return.')

build_collection_editor_from_capabilities = (capabilities_url) ->
  $.ajax capabilities_url,
    type: 'GET'
    dataType: 'xml'
    error: (jqXHR, textStatus, errorThrown) ->
      console.log "AJAX Error: #{textStatus}"
      $('.container > h1').after $('<div>').attr('class','alert alert-error').append("Error loading the collection capabilities URL \"#{cite_collection_editor_config['capabilities_url']}\".")
    success: (data) ->
      collections = $(data).find('citeCollection')
      select = $('<select>')
      select.append $('<option>').attr('value',$(collection).attr('class')).attr('data-name',$(collection).attr('name')).append($(collection).attr('description')) for collection in collections
      $(select).attr('id','collection_select')
      $(select).attr('style','width:100%')
      $('.container').append select

      set_selected_collection_from_hash_parameters()

      window.onpopstate = (event) ->
        $('#collection_select').chosen()
        set_selected_collection_from_hash_parameters()
 
      $('#collection_select').chosen()
      $('#collection_select').bind 'change', (event) =>
        $('#collection_select').trigger("liszt:updated")
        $('#collection_form').remove()
        $('.alert').remove()
        selected = $('#collection_select option:selected')[0]
        selected_collection = $(data).find("citeCollection[class=#{$(selected).attr('value')}]")[0]

        push_selected_collection()

        build_collection_form selected_collection
        unless get_cookie 'access_token'
          $('.container > h1').after $('<div>').attr('class','alert alert-warning').attr('id','oauth_access_warning').append('You have not authorized this application to access your Google Fusion Tables. ')
          $('#oauth_access_warning').append $('<a>').attr('href',google_oauth_url()).append('Click here to authorize.')
          disable_collection_form()
      $('#collection_select').change()

merge_config_parameters = ->
  if window.FUSION_TABLES_URI?
    FUSION_TABLES_URI = window.FUSION_TABLES_URI

  cite_collection_editor_config = $.extend({}, default_cite_collection_editor_config, window.cite_collection_editor_config)
  google_oauth_parameters_for_fusion_tables['client_id'] = cite_collection_editor_config['google_client_id']
  
  if location.hash.substring(1).length && !(parse_query_string()['state'])
     console.log "Setting OAuth URL parameter state: #{location.hash.substring(1)}"
     google_oauth_parameters_for_fusion_tables['state'] = location.hash.substring(1)
  
  return cite_collection_editor_config

# main collection editor entry point
$(document).ready ->
  unless $('#qunit').length
    cite_collection_editor_config = merge_config_parameters()
    
    set_access_token_cookie filter_url_params(parse_query_string())
 
    build_collection_editor_from_capabilities cite_collection_editor_config['capabilities_url']

google_oauth_parameters_for_fusion_tables =
  response_type: 'token'
  client_id: '891199912324.apps.googleusercontent.com'
  redirect_uri: window.location.href.replace("#{location.hash}",'')
  scope: 'https://www.googleapis.com/auth/fusiontables'
  approval_prompt: 'auto'

google_oauth_url =
  "https://accounts.google.com/o/oauth2/auth?#{$.param(google_oauth_parameters_for_fusion_tables)}"

build_input_for_valuelist = (valuelist) ->
  select = $('<select>')
  values = $(valuelist).find('value')
  select.append $('<option>').append($(value).text()) for value in values
  return select

build_input_for_property = (property) ->
  input = switch $(property).attr('type')
    when 'markdown'
      $('<textarea>').attr('style','width:100%;height:20em')
    when 'string'
      if $(property).find('valueList').length > 0
        build_input_for_valuelist $(property).find('valueList')[0]
      else
        $('<input>').attr('style','width:100%')
    when 'citeurn', 'citeimg'
      $('<input>').attr('style','width:100%')
    when 'datetime'
      $('<input>').attr('type','date')
    else
      console.log 'Error: unknown type'
      $('<input>')
  $(input).attr('id',$(property).attr('name'))

add_property_to_form = (property, form) ->
  form.append $('<br>')
  form.append $('<label>').attr('for',$(property).attr('name')).append($(property).attr('label') + ':')
  form.append build_input_for_property property

build_collection_form = (collection) ->
  form = $('<form>').attr('id','collection_form')
  properties = $(collection).find('citeProperty')
  add_property_to_form(property,form) for property in properties

  form.append $('<br>')
  form.append $('<a>').attr('href',google_oauth_url).append('OAuth Test')

  # test table access
  if get_cookie 'access_token'
    $.ajax "https://www.googleapis.com/fusiontables/v1/tables/#{$(collection).attr('class')}?access_token=#{get_cookie 'access_token'}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "AJAX Error: #{textStatus}"
      success: (data) ->
        console.log data

  $('.container').append form

parse_query_string = (query_string) ->
  params = {}
  if query_string.length > 0
    regex = /([^&=]+)=([^&]*)/g
    while m = regex.exec(query_string)
      params[decodeURIComponent(m[1])] = decodeURIComponent(m[2])
  return params

get_cookie = (key) ->
  key = key + "="
  for cookie_fragment in document.cookie.split(';')
    return cookie_fragment.replace(/^\s+/, '').substring(key.length, cookie_fragment.length) if cookie_fragment.indexOf(key) == 0
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
        console.log data
        access_token_expires = new Date
        access_token_expires.setTime(access_token_expires.getTime() + params['expires_in']*1000)
        access_token_cookie = "access_token=#{params['access_token']}; "
        access_token_cookie += "expires=#{access_token_expires.toGMTString()}; "
        access_token_cookie += "path=/"
        console.log 'Wrote access token cookie: ' + access_token_cookie
        document.cookie = access_token_cookie

$(document).ready ->
  set_access_token_cookie parse_query_string(location.hash.substring(1))
  # strip the hash from the URL, as Google will also reject any further queries if it's present
  history.replaceState(null,'',window.location.href.replace("#{location.hash}",''))
  if get_cookie 'access_token'
    console.log 'Read access token cookie: ' + get_cookie 'access_token'
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
        selected = $('#collection_select option:selected')[0]
        selected_collection = $(data).find("citeCollection[class=#{$(selected).attr('value')}]")[0]
        build_collection_form selected_collection
      $('#collection_select').change()

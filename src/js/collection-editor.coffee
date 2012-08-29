google_oauth_parameters_for_fusion_tables =
  response_type: 'token'
  client_id: '891199912324.apps.googleusercontent.com'
  redirect_uri: 'http://dl.dropbox.com/u/360471/cite-collection-editor/oauthcallback'
  scope: 'https://www.googleapis.com/auth/fusiontables.readonly'
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
  form.append $('<a>').attr('href',google_oauth_url).append('OAuth Test')
  $('.container').append form

$(document).ready ->
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

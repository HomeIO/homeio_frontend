class @HomeIOAddonOutputRenderer
  constructor: ->
    @name = null
    @container = null

    @addonObject = null


  start: () ->
    @getFromApi()

  getFromApi: () ->
    $.getJSON "/api/addons/" + @name + "/.json",  (data) =>
      @addonObject = data.object
      @render()

  render: () ->
    if @addonObject["array"]
      @renderArray(@addonObject["array"], @addonObject["keys"])

  renderArray: (array, keys) ->
    tableHtml = $('<table></table>').addClass('pure-table pure-table-striped addonDynamicTable')
    headHtml = $('<thead></thead')
    tableHtml.append(headHtml)
    rowHtml = $('<tr></tr>')
    headHtml.append(rowHtml)
    for keyDef in keys
      key = keyDef.key
      cellHtml = $('<th></th>').text(key)
      rowHtml.append(cellHtml)


    for row in array
      rowHtml = $('<tr></tr>')
      tableHtml.append(rowHtml)
      for keyDef in keys
        cellHtml = $('<td></td>').text(@processValue(row, keyDef))
        rowHtml.append(cellHtml)

    $(@container).append(tableHtml)

  # TODO refactor
  timeToString: (t) ->
    date = new Date(parseInt(t))
    formattedTime = date.getHours() + ':' + ('0' + date.getMinutes().toString()).slice(-2) + ':' + ('0' + date.getSeconds().toString()).slice(-2)
    formattedTime

  processValue: (row, keyDef) ->
    value = row[keyDef.key]

    if keyDef.type == "time"
      value = @timeToString(value)

    if keyDef.coeff
      value *= keyDef.coeff

    if keyDef.type == "float"
      value = Number(parseFloat(value)).toFixed(2)

    if keyDef.unit
      value = value + " " + keyDef.unit

    if keyDef.type == "interval"
      if value == 0
        value = "0 s"
      else
        value = moment().add(value).fromNow(true)

    return value

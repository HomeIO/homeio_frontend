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
        cellHtml = $('<td></td>').prop('title', row[keyDef.key])
        cellHtml.text(@processValue(row, keyDef))
        rowHtml.append(cellHtml)

    $(@container).append(tableHtml)

  timeToString: (t) ->
    date = new Date(parseInt(t))
    # dateFormat = require("dateformat")
    dateFormat date, "yyyy-mm-dd H:MM:ss"

  intervalToString: (timeInterval) ->
    # ms
    if timeInterval < 1000
      return timeInterval + " ms";
    else
      timeInterval = Math.round( timeInterval / 1000.0 )

    # s
    if timeInterval < 600
      return timeInterval + " s"
    else
      timeInterval = Math.round( timeInterval / 60.0 )

    # min
    if timeInterval < 600
      return timeInterval + " min"
    else
      timeInterval = Math.round( timeInterval / 60.0 )

    # hour
    if timeInterval < (24*7)
      return timeInterval + " h";
    else
      timeInterval = Math.round( timeInterval / 24.0 )

    return timeInterval + " days"


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
        value = @intervalToString(value)

    return value

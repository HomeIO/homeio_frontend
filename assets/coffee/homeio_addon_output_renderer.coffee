class @HomeIOAddonOutputRenderer
  constructor: ->
    @name = null
    @keyName = null
    @container = null

    @addonObject = null

    @useGraph = false


  start: () ->
    @getFromApi()

  getFromApi: () ->
    $.getJSON "/api/addons/" + @name + "/.json",  (data) =>
      @addonObject = data.object
      @render()

  render: () ->
    if @useGraph == false
      if @addonObject["array"]
        @renderArray(@addonObject["array"], @addonObject["keys"])
      else if @addonObject["hash"]
        @renderHash(@addonObject["hash"])
    else
      if @addonObject["array"]
        @renderGraph(@addonObject["array"], @addonObject["keys"])

  renderHash: (hash) ->
    tableHtml = $('<table></table>').addClass('pure-table pure-table-striped addonDynamicTable')
    headHtml = $('<thead></thead')
    tableHtml.append(headHtml)
    rowHtml = $('<tr></tr>')
    headHtml.append(rowHtml)

    cellHtml = $('<th></th>')
    cellHtml.text("Key")
    rowHtml.append(cellHtml)

    cellHtml = $('<th></th>')
    cellHtml.text("Value")
    rowHtml.append(cellHtml)

    $.each hash, (key, value) ->
      rowHtml = $('<tr></tr>')
      tableHtml.append(rowHtml)

      cellHtml = $('<td></td>')
      cellHtml.text(key)
      rowHtml.append(cellHtml)

      cellHtml = $('<td></td>')
      cellHtml.text(value)
      rowHtml.append(cellHtml)

    $(@container).append(tableHtml)

  renderArray: (array, keys) ->
    tableHtml = $('<table></table>').addClass('pure-table pure-table-striped addonDynamicTable')
    headHtml = $('<thead></thead')
    tableHtml.append(headHtml)
    rowHtml = $('<tr></tr>')
    headHtml.append(rowHtml)
    for keyDef in keys
      key = keyDef.key
      keyLink = key
      if key == "time"
        keyLink = "all"

      headerLink = $('<a></a>').attr("href", "/#/addons/" + @name + "/graph/" + keyLink)
      headerLink.text(key)
      cellHtml = $('<th></th>')
      cellHtml.append(headerLink)
      rowHtml.append(cellHtml)


    for row in array
      rowHtml = $('<tr></tr>')
      tableHtml.append(rowHtml)
      for keyDef in keys
        cellHtml = $('<td></td>').prop('title', row[keyDef.key])
        cellHtml.text(@processValue(row, keyDef))
        rowHtml.append(cellHtml)

    $(@container).append(tableHtml)

  renderGraph: (array, keys) ->
    graphElement = $(@container)

    # height
    h = $('body').height() - 40
    if h < 200
      h = 200
    graphElement.height(h)

    # options
    @flotOptions =
      series:
        lines:
          show: true
          fill: true
        points:
          show: false
      legend:
        show: true
      grid:
        clickable: false
        hoverable: true
      xaxis:
        mode: "time"
        timezone: "browser"

    if @keyName == "all"
      # use min/avg/max
      min_data = []
      avg_data = []
      max_data = []

      for row in array
        if row.time
          min_data.push([new Date(row.time), row.min])
          avg_data.push([new Date(row.time), row.avg])
          max_data.push([new Date(row.time), row.max])

      new_data =
        [
          data: max_data
          label: "max"
        ,
          data: avg_data
          label: "avg"
        ,
          data: min_data
          label: "min"
        ]

      console.log(new_data)
      @plot = $.plot graphElement, new_data, @flot_options

    else
      # use regular, one type
      new_data = []
      for row in array
        if row.time
          new_data.push([new Date(row.time), row[@keyName]])
        else
          new_data.push([row[@keyName]])

      @plot = $.plot graphElement, [new_data], @flot_options

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

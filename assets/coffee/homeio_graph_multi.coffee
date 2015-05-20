# get all meas types
# get all latest data
# controls: meas togglable buttons
# 1 - which graph 
# 2 - toggle visiblity/meas fetching

# types:
# - interval continuos
# - interval only 1 meas
# - fixed from-to (timestamps)
# - changeable active meases


class @HomeIOMeasGraphMulti
  constructor: ->
    # where everything from graph is located
    @container = null
    
    # fetched meases
    @meases = []
    # in hash format
    @measesHash = {}
    
    # fetched settings
    @settings = {}
    
    # which measurements are enabled
    @enabled = {}
    # all fetched data
    @buffer = {}
    # last fetches measurements
    @lastTime = {}
    
    # time ranges
    @timeFrom = null
    @timeTo = null
    # amount of seconds represented in graph
    @timeRange = 120 * 1000
    
    # refresh every miliseconds
    @periodicInterval = 4000
    
    # offset between server and client in miliseconds
    @serverTimeOffset = 0
    
    
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
     
    
  # run everything
  start: () ->
    @getFromApi()
  
  # helper, current timestamp in miliseconds
  currentTime: () ->
    (new Date()).getTime()
  
  # gets everything what is important for drawing graphs
  getFromApi: () ->
    $.getJSON "/api/settings.json",  (data) =>
      @settings = data
      
      $.getJSON "/api/meas.json",  (data) =>
        @meases = data.array
      
        # mark client-server time offset
        if @meases.length > 0
          # lower than 0 means time of last measurement from backend is lower than client current time
          @serverTimeOffset = @meases[0].buffer.lastTime - @currentTime()

        # prepare buffers and stuff
        for meas in @meases
          @measesHash[meas.name] = meas
          @buffer[meas.name] = []
      
        @render()
  
  # render controls and graph
  render: () ->
    @renderControls()
    @renderGraph()
    setInterval @renderGraph, @periodicInterval
  
  renderControls: () ->
    @renderMeasCheckboxes()
  
  # meas checkboxes are used to choose what measurements should be displayed
  renderMeasCheckboxes: () =>
    @containerCheckbox = @container + "_checkboxes"
    $("<div\>",
      id: @containerCheckbox.replace("#","")
      class: "multi-graph-checkbox-container"
    ).appendTo($(@container))
    
    for meas in @meases
      checkboxId = @containerCheckbox.replace("#","") + "_" + meas.name
      div = $("<div\>",
        class: "multi-graph-checkbox-element"
      )
      
      $("<input\>",
        type: "checkbox"
        name: meas.name
        id: checkboxId
        checked: null
        class: "multi-graph-checkbox"
        "data-meas-name": meas.name  
      ).appendTo(div)
      
      $("<label>" + meas.name + "</label>",
        for: checkboxId
      ).appendTo(div)
      
      div.appendTo($(@containerCheckbox))
    
    # dynamically update when checkboxes changed
    $(".multi-graph-checkbox").change (event) =>
      obj = $(event.currentTarget)
      name = obj.data("meas-name")
      @enabled[name] = obj.is(':checked')
      
      @renderGraph()
      
  renderGraph: () =>
    @recalculateTimeRanges()
    @normalizeDataForTime()
    @fetchRawData()
  
  # set time ranges for current graph
  recalculateTimeRanges: () =>
    @timeTo = @currentTime()
    @timeFrom = @timeTo - @timeRange
  
  # remove data older than @timeFrom
  normalizeDataForTime: () ->
    timeFrom = @timeFrom + @serverTimeOffset
    timeTo = @timeTo + @serverTimeOffset
 
    for meas in @meases
      oldBuffer = @buffer[meas.name]
      newBuffer = []
      
      # only use data in time range
      for d in oldBuffer
        if (d[0] >= timeFrom) && (d[0] <= timeTo)
          newBuffer.push d
      
      # must be sorted to eliminate quirks
      newBuffer = newBuffer.sort((a, b) ->
        a[0] - b[0]
      )
      
      @buffer[meas.name] = newBuffer

      # mark last time
      if newBuffer.length > 0
        @lastTime[meas.name] = newBuffer[newBuffer.length - 1][0]
        
  # fetch all needed data to render fresh graph  
  fetchRawData: () =>
    # fetch all enabled measurement raw data
    for measName in Object.keys(@enabled)
      if @enabled[measName]
        
        # calculate timeFrom, add offset
        timeFrom = @timeTo - @timeRange
        console.log @lastTime
        if @lastTime[measName]
          timeFrom = @lastTime[measName]
        
        timeFrom += @serverTimeOffset
        timeTo = @timeTo + @serverTimeOffset
        
        url = "/api/meas/" + measName + "/raw_for_time/" + timeFrom + "/" + timeTo + "/.json"
        $.getJSON url, (response) =>
          measName = response.meas_type
          length = response.data.length
          i = 0
      
          for d in response.data
            x = (response.lastTime - ((length - i) * response.interval))
            y = ( parseFloat(d) + @measesHash[measName].coefficientOffset ) * @measesHash[measName].coefficientLinear
            
            i += 1
            @buffer[measName].push [x, y]
          
          
    graphData = []
    for measName in Object.keys(@buffer)
      if @enabled[measName]
        graphData.push {"label": measName, "data": @buffer[measName]}
    
    #console.log @buffer
    @containerGraph = @container + "_graph"
    
    $("<div\>",
      id: @containerGraph.replace("#","")
      class: "multi-graph-graph-container"
    ).appendTo($(@container))

    
    $(@containerGraph).height(900)
    $(@containerGraph).width(900)
    
    if @plot
      @plot.setData(graphData)
      @plot.setupGrid();
      @plot.draw()
    else  
      @plot = $.plot $(@containerGraph), graphData , @flotOptions   
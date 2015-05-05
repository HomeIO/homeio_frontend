class @HomeIOMeasGraph
  constructor: ->
    # graph is rendered from
    @buffer = []
    # get raw values every miliseconds
    @periodicInterval = 2000
    # store max measurements in class buffer
    @maxBufferSize = 100
    
    # get only 1 new value when using periodic
    @onlyOneRawValue = false
    
    # uses history mode - get measurements for big amount of time, not all, but every some
    @historyMode = false
    @historyLength = 3600*1000

    @showControls = true

    @xUnit = "seconds"
    @yUnit = ""

    @flot_options =
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
  
  prepare: () ->
    @getMeas()
    @prepareHtml()

  prepareHtml: () ->
    if @showControls
      @elementContainer = @element
      @elementGraph = "#" + @meas_name + "_graph"
      @elementControls = "#" + @meas_name + "_controls"
      @elementLastTime = "#" + @meas_name + "_lastTime"
      @elementUnit = "#" + @meas_name + "_Unit"
      
      $("<div\>",
        id: @elementGraph.replace("#","")
        style: "width: " + $(@elementContainer).width() + "px; height: " + $(@elementContainer).height() + "px"
      ).appendTo(@elementContainer)  

      console.log($(@elementContainer))
      

      $("<div\>",
        id: @elementControls.replace("#","")
        class: "graph-control"
      ).appendTo(@elementContainer)      

      # last time
      $("<div\>",
        id: @elementLastTime.replace("#","")
        class: "graph-last-time"
      ).appendTo(@elementControls)      

      # x unit
      $("<div\>",
        id: @elementUnit.replace("#","")
        class: "graph-units"
      ).appendTo(@elementControls)       
      
      
    else
      @elementGraph = @element
    

  currentTime: () ->
    (new Date()).getTime()
    
  timeToString: (t) ->
    date = new Date(parseInt(t))
    formattedTime = date.getHours() + ':' + ('0' + date.getMinutes().toString()).slice(-2) + ':' + ('0' + date.getSeconds().toString()).slice(-2)
    formattedTime

  getMeas: () ->
    $.getJSON "/api/meas/" + @meas_name + "/.json",  (data) =>
      @meas = data.object
      #console.log(@meas)
      
      # time for first raw data get
      @interval = @meas.buffer.interval
      @getTo = @meas.buffer.lastTime
      @getFrom = @meas.buffer.lastTime - @maxBufferSize * @interval
      
      @yUnit = @meas.unit
      
      # add to localtime to get backend time
      @localTimeOffset = @meas.buffer.lastTime - @currentTime()
      #console.log @localTimeOffset
      
      @getRaw()
      setInterval @getRaw, @periodicInterval
      
  getRaw: () =>
    @getTo = @currentTime() + @localTimeOffset
    
    if @onlyOneRawValue
      url = "/api/meas/" + @meas.name + "/raw_for_index/0/0/.json"
    else if @historyMode
      @getFrom = @getTo - @historyLength
      url = "/api/meas/" + @meas.name + "/raw_history_for_time/" + @getFrom + "/" + @getTo + "/" + @maxBufferSize + "/.json"
    else
      url = "/api/meas/" + @meas.name + "/raw_for_time/" + @getFrom + "/" + @getTo + "/.json"
    
    $.getJSON url,  (data) =>
      #console.log(data)
      
      # next get from last time point
      @getFrom = @getTo
      # store interval for time calculation
      @interval = data.interval
      # used in controls
      @lastTime = data.lastTime
      
      @addToBuffer(data.data)
      @renderGraph()
      @afterRender()
      
      
  addToBuffer: (array) ->
    for d in array
      if @buffer.length >= @maxBufferSize
        @buffer.shift()
        
      @buffer.push(d)

  renderGraph: () ->
    new_data = []
    i = 0
    extremeX = 0
    
    for d in @buffer
      x = ((i - @buffer.length) * @interval) / 1000.0
      y = ( parseFloat(d) + @meas.coefficientOffset ) * @meas.coefficientLinear
      
      if Math.abs(x) > extremeX
        extremeX = Math.abs(x)
      
      new_d = [x, y]
      new_data.push new_d
      i += 1


    if new_data.length > 0
      @divideX = 1.0
      if extremeX > 24.0*60.0*60.0
        # days
        @xUnit = "days"
        @divideX = 24.0*60.0*60.0
        
      else if extremeX > 60.0*60.0
        # hours
        @xUnit = "hours"
        @divideX = 60.0*60.0
        
      else if extremeX > 60.0  
        # minutes
        @xUnit = "minutes"
        @divideX = 60.0
        
      if @divideX != 1.0
        old_data = new_data
        new_data = []
        for d in old_data
          new_d = [d[0] / @divideX, d[1]]
          new_data.push new_d

    new_data =
      data: new_data
      color: "#55f"
      label: name

    if @plot
      @plot.setData([new_data])
      @plot.setupGrid();
      @plot.draw()
    else
      @plot = $.plot $(@elementGraph), [new_data], @flot_options      

        
      
  afterRender: () ->
    if @elementLastTime
      $(@elementLastTime).html(@timeToString(@lastTime))
    if @elementUnit
      $(@elementUnit).html(@yUnit + " / " + @xUnit)

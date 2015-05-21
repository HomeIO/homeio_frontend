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
    # which data were processed now
    @processedReady = {}
    
    # time ranges
    @timeFrom = null
    @timeTo = null
    # amount of seconds represented in graph
    @timeRange = 60 * 1000
    
    # refresh every miliseconds, default value
    @periodicInterval = 4000
    # more inteligent way to calculate interval
    # usable in all systems
    @periodicDynamic = false
    @periodicDynamicMultiplier = 5
    @periodicDynamicMinimum = 2000
    @periodicDynamicMaximum = 10000
    
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
        timezone: "browser"
     
    
  # run everything
  start: () ->
    @getFromApi()
  
  # helper, current timestamp in miliseconds
  currentTime: () ->
    (new Date()).getTime()
  
  # gets everything what is important for drawing graphs
  getFromApi: () ->
    $.getJSON "/api/settings.json",  (data) =>
      @settings = data.object
      @calculateInterval()
      
      $.getJSON "/api/meas.json",  (data) =>
        @meases = data.array
      
        # mark client-server time offset
        if @meases.length > 0
          # lower than 0 means time of last measurement from backend is lower than client current time
          @serverTimeOffset = @meases[0].buffer.lastTime - @currentTime()
          console.log "server time offset " + @serverTimeOffset

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
 
  # some systems are dynamic, some not
  # allow it to use one frontend code to all graphs and all systems
  calculateInterval: () ->
    if @periodicDynamic
      oldInterval = @periodicInterval
      @periodicInterval = @settings.meas.cycleInterval * @periodicDynamicMultiplier
        
      if @periodicInterval < @periodicDynamicMinimum 
        @periodicInterval = @periodicDynamicMinimum
      if @periodicInterval > @periodicDynamicMaximum 
        @periodicInterval = @periodicDynamicMaximum
        
      if @periodicInterval != oldInterval
        console.log "interval changed from " + oldInterval + " to " + @periodicInterval
  
  # meas checkboxes are used to choose what measurements should be displayed
  # it renders also graph container
  renderControls: () =>
    @containerCheckbox = @container + "_checkboxes"
    @containerGraph = @container + "_graph"
    
    $(@container).addClass("multi-graph-container")
    
    $("<div\>",
      id: @containerGraph.replace("#","")
      class: "multi-graph-graph-container resizable"
    ).appendTo($(@container))
    
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
      
      console.log "meas " + name + " is " + @enabled[name]
      
      # when user disable meas type from graph
      # clean buffer to maintain data when
      # enabling it in future
      if @enabled[name] != true
        @buffer[name] = []
        @lastTime[name] = null
      
      @renderGraph()

    # hax for maximizing graph area
    $(@containerGraph).resize (event) =>
      @plot = null
      @plotGraph()
      
 
  # fetch all needed data to render fresh graph  
  renderGraph: () =>
    # set time ranges for current graph
    @timeTo = @currentTime()
    @timeFrom = @timeTo - @timeRange
    
    # allow to render 0 meas types
    enabledCount = 0
    
    # fetch all enabled measurement raw data
    for measName in Object.keys(@enabled)
      if @enabled[measName]
        enabledCount += 1
        
        # mark as this meas type is NOT ready
        @processedReady[measName] = false

        # calculate timeFrom, add offset
        timeFrom = @timeTo - @timeRange
        if @lastTime[measName]
          if @lastTime[measName] > timeFrom
            timeFrom = @lastTime[measName]
        
        timeFrom += @serverTimeOffset
        timeTo = @timeTo + @serverTimeOffset
        
        url = "/api/meas/" + measName + "/raw_for_time/" + timeFrom + "/" + timeTo + "/.json"
        $.getJSON url, (response) =>
          measName = response.meas_type
          length = response.data.length
          i = 0
      
          for d in response.data
            # convert raw values to [time,value]
            x = (response.lastTime - ((length - i) * response.interval))
            y = ( parseFloat(d) + @measesHash[measName].coefficientOffset ) * @measesHash[measName].coefficientLinear
            
            i += 1
            @buffer[measName].push [x, y]
          
          # normalize data after fetch and first process
          oldBuffer = @buffer[measName]
          newBuffer = []
      
          # only use data in time range
          for d in oldBuffer
            if (d[0] >= @timeFrom) && (d[0] <= @timeTo)
              newBuffer.push d
      
          # must be sorted to eliminate quirks
          newBuffer = newBuffer.sort((a, b) ->
            a[0] - b[0]
          )
      
          # replace normalized array
          @buffer[measName] = newBuffer

          # mark last time
          if newBuffer.length > 0
            @lastTime[measName] = newBuffer[newBuffer.length - 1][0]
            
          # mark as this meas type is ready
          @processedReady[measName] = true
          
          # render graph if all meas types were fetched and processed
          if @isAllDataReadyToPlot()
            @plotGraph()

    # there is no graph enabled, render empty
    if enabledCount == 0
      @plotGraph()


  isAllDataReadyToPlot: () =>
    ready = true
    for measName in Object.keys(@enabled)
      if @enabled[measName]
        if @processedReady[measName]
          # ok
        else
          ready = false
    return ready      
        
  
  plotGraph: () =>  
    graphData = []
    for measName in Object.keys(@buffer)
      if @enabled[measName]
        graphData.push {"label": measName, "data": @buffer[measName]}
    
    if @plot
      @plot.setData(graphData)
      @plot.setupGrid();
      @plot.draw()
    else  
      @plot = $.plot $(@containerGraph), graphData , @flotOptions   
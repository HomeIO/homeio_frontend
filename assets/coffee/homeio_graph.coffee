class @HomeIOMeasGraph
  constructor: ->
    # graph is rendered from
    @buffer = []
    # get raw values every miliseconds
    @periodicInterval = 1000
    # store max measurements in class buffer
    @maxBufferSize = 100
    
    @onlyOneRawValue = false

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

  currentTime: () ->
    (new Date()).getTime()

  getMeas: () ->
    $.getJSON "/api/meas/" + @meas_name + "/.json",  (data) =>
      @meas = data.object
      #console.log(@meas)
      
      # time for first raw data get
      @getFrom = @meas.buffer.lastTime
      @getTo = @meas.buffer.lastTime
      # add to localtime to get backend time
      @localTimeOffset = @meas.buffer.lastTime - @currentTime()
      console.log @localTimeOffset
      
      @getRaw()
      setInterval @getRaw, @periodicInterval
      
  getRaw: () =>
    @getTo = @currentTime() + @localTimeOffset
    
    if @onlyOneRawValue
      url = "/api/meas/" + @meas.name + "/raw_for_index/0/0/.json"
    else
      url = "/api/meas/" + @meas.name + "/raw_for_time/" + @getFrom + "/" + @getTo + "/.json"
    
    $.getJSON url,  (data) =>
      #console.log(data)
      
      # next get from last time point
      @getFrom = @getTo
      # store interval for time calculation
      @interval = data.interval
      
      @addToBuffer(data.data)
      @renderGraph()
      
      
  addToBuffer: (array) ->
    for d in array
      if @buffer.length >= @maxBufferSize
        @buffer.shift()
        
      @buffer.push(d)

  renderGraph: () ->
    new_data = []
    i = 0

    for d in @buffer
      x = ((i - @buffer.length) * @interval) / 1000.0
      y = ( parseFloat(d) + @meas.coefficientOffset ) * @meas.coefficientLinear
      
      new_d = [x, y]
      new_data.push new_d
      i += 1

    new_data =
      data: new_data
      color: "#55f"
      label: name

    if @plot
      @plot.setData([new_data])
      @plot.setupGrid();
      @plot.draw()
    else
      @plot = $.plot $(@element), [new_data], @flot_options      

class @HomeIOMeasGraphBad
  constructor: ->
    @buffer = []
    @initial_time = (new Date()).getTime()
    @last_time = @initial_time
    
    @periodic = true
    @periodic_interval = 3000
    
    # true - get partialy all raw, false - get last only
    @periodic_get_all = true #TODO
    
    @buffer_max_size = 200

    # default graph options
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

  
  name: (meas_name) ->
    @meas = {"name": meas_name, "interval": 1}
    @meas_interval = @meas.interval
  
  addToBuffer: (array) =>
    for r in array
      if @buffer.length >= @buffer_max_size
        @buffer.shift()
      @buffer.push(r)
    #console.log(@buffer)  
  
  drawGraph: () =>
    page = 0
    coefficient_linear = @meas["coefficientLinear"]
    coefficient_offset = @meas["coefficientOffset"]
    interval = @meas_interval
    current_time = (new Date).getTime()
    time_offset = @last_time - current_time - page * interval * @buffer.length
    time_offset_last = current_time - @last_time
    max_page = 1 # data["range"]["max_page"]
    unit = "unit" # meas_data["unit"]
    
    new_data = []
    i = 0

    for d in @buffer
      x = -1 * i * interval + time_offset
      y = ( parseFloat(d) + coefficient_offset ) * coefficient_linear
      
      #console.log x, y

      new_d = [x, y]
      new_data.push new_d
      i += 1

    new_data =
      data: new_data
      color: "#55f"
      label: @meas.name
    
    if @plot
      @plot.setData(new_data)
      @plot.draw()
    else  
      @plot = $.plot $(@element), new_data, @flot_options  
  
  getRaw: () =>
    from = @last_time
    to = (new Date()).getTime()
    $.getJSON "/api/meas/" + @meas.name + "/raw_for_time/" + from + "/" + to + "/.json",  (data) =>
      @meas_interval = data.interval
      #console.log @meas_interval
      @last_time = to
      @addToBuffer(data.data)
      @drawGraph()
      
      #console.log(data)
  
  getRawInterval: () =>
    if (@periodic)
      @getRaw()
  
  start: () ->
    $.getJSON "/api/meas/" + @meas.name + "/.json",  (data) =>
      @meas = data.object
      @coefficient_linear = @meas["coefficientLinear"]
      @coefficient_offset = @meas["coefficientOffset"]      
      @getRaw()
      setInterval @getRawInterval, @periodic_interval


class @HomeIOMeasGraphOld
  meas_graph: (meas_data, graph_data, element) ->
    #console.log(graph_data)
    #console.log(meas_data)
    
    flot_options =
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

    page = 0
    buffer = graph_data["data"]
    coefficient_linear = meas_data["object"]["coefficientLinear"]
    coefficient_offset = meas_data["object"]["coefficientOffset"]
    interval = graph_data["interval"]
    last_time = graph_data["lastTime"]
    current_time = (new Date).getTime()
    time_offset = last_time - current_time - page * interval * buffer.length
    time_offset_last = current_time - last_time
    chart_length = $(element).width()
    max_page = 1 # data["range"]["max_page"]
    unit = "unit" # meas_data["unit"]

    # time ranges
    #$("#time-from").html(data["range"]["time_from"])
    #$("#time-to").html(data["range"]["time_to"])
    #$("input[name=max_page]").html(max_page)

    new_data = []
    i = 0

    for d in buffer
      x = -1 * i * interval + time_offset
      y = ( parseFloat(d) + coefficient_offset ) * coefficient_linear
      
      console.log d, coefficient_offset, coefficient_linear

      new_d = [x, y]
      new_data.push new_d
      i += 1

    if new_data.length > chart_length
      factor = Math.ceil(parseFloat(new_data.length) / parseFloat(chart_length))
      smooth_data = averageData(new_data, factor + smooth)
      new_data = smooth_data

    #$("#chart-info").html("<strong>" + buffer.length + "</strong> measurements")
    if buffer.length > 0
      time_range = new_data[0][0] - new_data[new_data.length - 1][0]
      #$("#chart-info").html($("#chart-info").html() + ", " + "<strong>" + time_range + "</strong> seconds")
      #$("#chart-info").html($("#chart-info").html() + ", " + "<strong>" + Math.round(time_offset_last) + "</strong> seconds ago")

    latest_unix_rel_time = new_data[0][0]
    oldest_unix_rel_time = new_data[new_data.length - 1][0]
    center_unix_rel_time = (latest_unix_rel_time + oldest_unix_rel_time) / 2.0
    offset_unix_rel_time = latest_unix_rel_time - center_unix_rel_time

    new_data =
      data: new_data
      color: "#55f"
      label: name

    console.log(new_data)

    $.plot $(element), [new_data], flot_options
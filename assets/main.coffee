class @HomeIOMeasGraph
  meas_graph: (meas_data, graph_data, element) ->
    console.log(graph_data)
    console.log(meas_data)
    
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
    

app = $.sammy("#main", ->
  @use "Haml"
  
  @get "#/", (context) ->
    context.app.swap('')
    context.render("/assets/templates/index.haml",
    ).appendTo context.$element()

  @get "#/measurements", (context) ->
    @load("/api/meas.json").then (data) ->
      context.partial "/assets/templates/meas/index.haml", (html) ->
        $("#main").html html
        for meas, index in data["array"]
          context.render "/assets/templates/meas/_index_item.haml", {meas: meas}, (meas_html) ->
            $("#measArray").append meas_html
            
  @get "#/measurements/:measName", (context) ->
    context.app.swap('')
    @load("/api/meas/" + @params["measName"] + "/.json").then (data) ->
      meas = data["object"]
      context.render("/assets/templates/meas/show.haml",
        meas: meas
      ).appendTo context.$element()

  @get "#/measurements/:measName/graph", (context) ->
    context.app.swap('')
    @load("/api/meas/" + @params["measName"] + "/.json").then (meas_data) ->
      meas = meas_data["object"]
      @load("/api/meas/" + meas.name + "/raw_for_index/0/100/.json").then (graph_data) ->
        context.render("/assets/templates/meas/graph.haml",
          meas: meas
          graph_data: graph_data
        ).appendTo(context.$element()).then (html) ->
          h = new HomeIOMeasGraph
          h.meas_graph(meas_data, graph_data, "#graph")

  @get "#/actions", (context) ->
    @load("/api/actions.json").then (data) ->
      context.partial "/assets/templates/actions/index.haml", (html) ->
        $("#main").html html
        for action, index in data["array"]
          context.render "/assets/templates/actions/_index_item.haml", {action: action}, (action_html) ->
            $("#actionArray").append action_html

  @get "#/actions/:actionName", (context) ->
    context.app.swap('')
    @load("/api/actions/" + @params["actionName"] + "/.json").then (data) ->
      action = data["object"]
      context.render("/assets/templates/actions/show.haml",
        action: action
      ).appendTo context.$element()


  @get "#/overseers", (context) ->
    @load("/api/overseers.json").then (data) ->
      context.partial "/assets/templates/overseers/index.haml", (html) ->
        $("#main").html html
        for overseer, index in data["array"]
          context.render "/assets/templates/overseers/_index_item.haml", {overseer: overseer}, (overseer_html) ->
            $("#overseerArray").append overseer_html

  @get "#/overseers/:overseerName", (context) ->
    context.app.swap('')
    @load("/api/overseers/" + @params["overseerName"] + "/.json").then (data) ->
      overseer = data["object"]
      context.render("/assets/templates/overseers/show.haml",
        overseer: overseer
      ).appendTo context.$element()



)
$ ->
  app.run "#/"

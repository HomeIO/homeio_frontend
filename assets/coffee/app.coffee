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

  @get "#/measurements/:measName/graph3", (context) ->
    context.app.swap('')
    context.render("/assets/templates/meas/graph2.haml",
        meas_name: @params["measName"]           
      ).then (html) =>
      #g = new HomeIOMeasGraph
      #g.name(@params["measName"])
      #g.element = "#graph"
      #g.start()
      html
    .appendTo context.$element()  

  @get "#/measurements/:measName/graph", (context) ->
    context.app.swap('')
    context.render("/assets/templates/meas/graph2.haml",
      meas_name: @params["measName"]
    ).appendTo context.$element()  
      
  @get "#/measurements/:measName/graph4", (context) ->
    @load("/api/meas/" + @params["measName"] + "/.json").then (meas_data) ->
      meas = meas_data["object"]
      @load("/api/meas/" + meas.name + "/raw_for_index/0/100/.json").then (graph_data) ->
        context.render("/assets/templates/meas/graph.haml",
          meas: meas
          graph_data: graph_data
        ).appendTo(context.$element()).then (html) ->
          g = new HomeIOMeasGraphOld
          g.meas_graph(meas_data, graph_data, "#graph")
          
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

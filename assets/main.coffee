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

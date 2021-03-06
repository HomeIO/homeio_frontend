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

  @get "#/graph", (context) ->
    context.app.swap('')

    context.render("/assets/templates/multigraph/dashboard.haml",
    ).appendTo context.$element()

  @get "#/graph/:range/:meases", (context) ->
    context.app.swap('')

    subname = 'Multigraph - ' + @params['range'] + ' seconds range'
    if @params['range'] < 0
      subname = 'Multigraph - full range'

    context.render("/assets/templates/multigraph/graph.haml",
                    range: @params['range'],
                    meases: @params['meases'],
                    subname: subname
    ).appendTo context.$element()

  @get "#/measurements/:measName", (context) ->
    context.app.swap('')
    @load("/api/meas/" + @params["measName"] + "/.json").then (data) ->
      meas = data["object"]
      context.render("/assets/templates/meas/show.haml",
        meas: meas
      ).appendTo context.$element()

  @get "#/measurements/:measName/graph", (context) ->
    context.app.swap('')
    context.render("/assets/templates/meas/graph_detailed.haml",
      meas_name: @params["measName"]
    ).appendTo context.$element()

  @get "#/measurements/:measName/history", (context) ->
    context.app.swap('')
    context.render("/assets/templates/meas/graph_history.haml",
      meas_name: @params["measName"]
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

  @post '#/actions/execute', (context) ->
    $.ajax(
      type: "POST"
      url: "/api/actions/" + @params["name"] + "/execute.json"
      data:
        password: md5(@params['password'])
        name: @params['name']
      dataType: "JSON"
    ).done (executeData) ->
      # i know it's lame :(
      setTimeout (->

        if executeData.status == 0
          $(".action-execute-button").removeClass("pure-button-primary")
          $(".action-execute-button").removeClass("button-error")
          $(".action-execute-button").addClass("button-success")

        else
          $(".action-execute-button").removeClass("pure-button-primary")
          $(".action-execute-button").removeClass("button-success")
          $(".action-execute-button").addClass("button-error")


      ), 500

    context.redirect("#/actions/" + @params["name"])



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


  @get "#/addons", (context) ->
    @load("/api/addons.json").then (data) ->
      context.partial "/assets/templates/addons/index.haml", (html) ->
        $("#main").html html
        for addon, index in data["array"]
          context.render "/assets/templates/addons/_index_item.haml", {addon: addon}, (addon_html) ->
            $("#addonsArray").append addon_html


  @get "#/addons/:addonName", (context) ->
    context.app.swap('')
    @load("/api/addons/" + @params["addonName"] + "/.json").then (data) ->
      addon = data["object"]
      context.render("/assets/templates/addons/show.haml",
        addon: addon
      ).appendTo context.$element()

  @get "#/addons/:addonName/graph/:keyName", (context) ->
    context.app.swap('')
    keyName = @params["keyName"]
    @load("/api/addons/" + @params["addonName"] + "/.json").then (data) ->
      addon = data["object"]
      context.render("/assets/templates/addons/graph.haml",
        addon: addon
        keyName: keyName
      ).appendTo context.$element()


  @get "#/stats", (context) ->
    context.app.swap('')
    @load("/api/stats.json").then (data) ->
      stats = data["object"]
      context.render("/assets/templates/stats/show.haml",
        stats: stats
      ).appendTo context.$element()


)
$ ->
  app.run "#/"

  # TODO make is usable on all pages
  # TODO not executed after changing url, without F5

  # custom  snippet to make multi-graph big
  $(window).resize (event) =>
    if $.data(this, "resizeBlock") != true
      $.data(this, "resizeBlock", true)

      clearTimeout $.data(this, "resizeTimer")
      $.data this, "resizeTimer", setTimeout(=>
        #console.log("resize")

        h = event.currentTarget.innerHeight
        $('body').height(h)
        $('#layout').height(h)
        $('.content').height(h)

        innerObj = $(".content-inner")
        if innerObj
          element = innerObj.get(0)
          paddingTop = 60 # yeah :>
          oh = element.offsetTop - element.scrollTop + element.clientTop + paddingTop
          ih = h - oh

          if h > 200
            $('.content-inner').height(ih)

        $('.resizable').trigger('resize')
        $.data(this, "resizeBlock", false)

      , 100)

   setTimeout(=>
    $(window).trigger('resize')
   , 20)

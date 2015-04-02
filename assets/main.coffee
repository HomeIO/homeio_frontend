app = $.sammy("#main", ->
  @use "Haml"
  
  @get "#/", (context) ->
    context.app.swap('')
    context.render("/assets/templates/index.haml",
    ).appendTo context.$element()

  @get "#/measurements", (context) ->
    @load("/measIndex.json").then (data) ->
      context.app.swap('')
      for meas, index in data["array"]
        context.log(meas)
        context.render("/assets/templates/meas_partial.haml",
          meas: meas
          index: index
        ).appendTo context.$element()

  @get "#/measurements2", (context) ->
    @load("/measIndex.json").then (data) ->
      context.partial "/assets/templates/meas_array.haml", (html) ->
        $("#main").html html
        for meas, index in data["array"]
          console.log(meas)
          context.render "/assets/templates/meas_partial.haml", {meas: meas}, (meas_html) ->
            $("#measArray").append meas_html
          

  @get "#/measurements3", (context) ->
    @load("/measIndex.json").then (data) ->
      context.app.swap('')
      context.render("/assets/templates/meas_array.haml",
                     data: data
      ).appendTo context.$element()


  @get "#/measurements/:measName", (context) ->
    context.app.swap('')
    context.log(@params['measName'])

)
$ ->
  app.run "#/"

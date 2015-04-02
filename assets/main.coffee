app = $.sammy("#main", ->
  @use "Haml"
  
  @get "#/", (context) ->
    context.app.swap('')
    context.render("/assets/templates/index.haml",
    ).appendTo context.$element()

  @get "#/measurements", (context) ->
    @load("/measDetails.json").then (data) ->
      context.app.swap('')
      for meas, index in data["array"]
        context.render("/assets/templates/meas.haml",
          meas: meas
          index: index
        ).appendTo context.$element()

  @get "#/measurements/:measName", (context) ->
    context.app.swap('')
    context.log(@params['measName'])

)
$ ->
  app.run "#/"

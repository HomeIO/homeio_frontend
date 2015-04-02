app = $.sammy("#main", ->
  @use "Haml"
  
  @get "#/", (context) ->
    context.app.swap('')
    context.render("/assets/templates/index.haml",
    ).appendTo context.$element()

  @get "#/measurements", (context) ->
    @load("/measIndex.json").then (data) ->
      context.partial "/assets/templates/meas_array.haml", (html) ->
        $("#main").html html
        for meas, index in data["array"]
          console.log(meas)
          context.render "/assets/templates/meas_partial.haml", {meas: meas}, (meas_html) ->
            $("#measArray").append meas_html
            
  @get "#/measurements/:measName", (context) ->
    context.app.swap('')
    context.log(@params['measName'])

)
$ ->
  app.run "#/"

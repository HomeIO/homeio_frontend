class @HomeIOMeasValuePeriodic
  constructor: ->
    @periodicInterval = 1000
  
  currentTime: () ->
    (new Date()).getTime()
    
  timeToString: (t) ->
    date = new Date(parseInt(t))
    formattedTime = date.getHours() + ':' + ('0' + date.getMinutes().toString()).slice(-2) + ':' + ('0' + date.getSeconds().toString()).slice(-2)
    formattedTime

  getMeas: () ->
    @getValues()
    setInterval @getValues, @periodicInterval
      
  getValues: () =>
    $.getJSON "/api/meas.json",  (data) =>
      for meas, index in data["array"]
        name = meas.name
        value = Number(parseFloat(meas.value)).toFixed(2)
        $("[data-meas-name='" + name + "'] .meas-value").html(value)
      $("#lastUpdated").html(@timeToString(@currentTime()) )

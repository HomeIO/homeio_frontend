# get all meas types
# get all latest data
# controls: meas togglable buttons
# 1 - which graph 
# 2 - toggle visiblity/meas fetching

# types:
# - interval continuos
# - interval only 1 meas
# - fixed from-to (timestamps)
# - changeable active meases


class @HomeIOMeasGraphMulti
  constructor: ->
    # where everything from graph is located
    @container = null
    
    # hash which measurements are enabled
    @enabled = {}
    
    
    
    # time ranges
    @timeFrom = null
    @timeTo = null
    
    
  
  start: () ->
    @getFromApi()
  
  # gets everything what is important for drawing graphs
  getFromApi: () ->
    $.getJSON "/api/settings.json",  (data) =>
      @settings = data
      @renderIfPossible()
      
    $.getJSON "/api/meas.json",  (data) =>
      @meases = data.array
      @renderIfPossible()
  
  # render controls and graph only if everything needed is fetched already
  renderIfPossible: () ->
    if @meases && @settings
      @renderControls()
  
  renderControls: () ->
    @renderMeasCheckboxes()
  
  # meas checkboxes are used to choose what measurements should be displayed
  renderMeasCheckboxes: () =>
    @containerCheckbox = @container + "_checkboxes"
    $("<div\>",
      id: @containerCheckbox.replace("#","")
      class: "multi-graph-checkbox-container"
    ).appendTo($(@container))
    
    for meas in @meases
      checkboxId = @containerCheckbox.replace("#","") + "_" + meas.name
      div = $("<div\>",
        class: "multi-graph-checkbox-element"
      )
      
      $("<input\>",
        type: "checkbox"
        name: meas.name
        id: checkboxId
        checked: null
        class: "multi-graph-checkbox"
        "data-meas-name": meas.name  
      ).appendTo(div)
      
      $("<label>" + meas.name + "</label>",
        for: checkboxId
      ).appendTo(div)
      
      div.appendTo($(@containerCheckbox))
    
    # dynamically update when checkboxes changed
    $(".multi-graph-checkbox").change (event) =>
      obj = $(event.currentTarget)
      name = obj.data("meas-name")
      @enabled[name] = obj.is(':checked')
      
      @renderGraph()
      
  renderGraph: () ->
    @getData()
  
  isMeasEnabled: (meas) ->
    @enabled[meas] == true
  
  getData: () ->
    for meas in Object.keys(@enabled)
      if @isMeasEnabled?(meas)
        console.log(meas)
  
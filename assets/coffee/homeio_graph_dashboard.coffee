class @HomeIOMeasGraphDashboard
  constructor: ->
    @container = null
    
    # fetched meases
    @meases = []
    # in hash format
    @measesHash = {}
    
    @enabled = {}
    
    @checkedMeases = 'default'
    
    @range = 0
    
    # fetched settings
    @settings = {}
  # run everything
  start: () ->
    @getFromApi()
  
  # helper, current timestamp in miliseconds
  currentTime: () ->
    (new Date()).getTime()
  
  # gets everything what is important for drawing dashboard
  getFromApi: () ->
    $.getJSON "/api/settings.json",  (data) =>
      @settings = data.object
      
      $.getJSON "/api/meas.json",  (data) =>
        @meases = data.array
      
        # prepare buffers and stuff
        for meas in @meases
          @measesHash[meas.name] = meas
      
        @render()

  renderCheckboxes: () ->
    @containerCheckbox = "#dashboard-checkboxes"
    $("<div\>",
      id: @containerCheckbox.replace("#","")
      class: "multi-graph-checkbox-container"
    ).appendTo($(@container))
    
    for meas in @meases
      checkboxId = @containerCheckbox.replace("#","") + "_" + meas.name
      div = $("<div\>",
        class: "multi-graph-checkbox-element"
      )

      if @checkedMeases == null
        @checkedMeases = ""

      # not selected is default
      is_checked = false

      # preselected meases are in url
      if (@checkedMeases.indexOf(meas.name) > -1)
        is_checked = true

      # when 'default' in url, show all with priority > 0
      if @checkedMeases == 'default'
        if parseInt(meas.priority) > 0
          is_checked = true
      
      console.log is_checked
      
      if is_checked
        # prepare array and start getting data
        @enabled[meas.name] = true
      
      $("<input\>",
        type: "checkbox"
        name: meas.name
        id: checkboxId
        checked: is_checked
        class: "multi-graph-checkbox"
        "data-meas-name": meas.name  
      ).appendTo(div)
      
      $("<label>" + meas.name + "</label>",
        for: checkboxId
      ).appendTo(div)
      
      div.appendTo($(@containerCheckbox))

    $(".multi-graph-checkbox").change (event) =>
      obj = $(event.currentTarget)
      name = obj.data("meas-name")
      @enabled[name] = obj.is(':checked')

      @renderLinks()
 
  renderLinks: () ->
    @linksCheckbox = "#dashboard-links"
    
    $(@linksCheckbox).remove()
    
    div = $("<div\>",
      id: @linksCheckbox.replace("#","")
      class: "multi-graph-links-container"
    ).appendTo($(@container))
    
    @checkedMeases = ""
    for meas in @meases
      if @enabled[meas.name]
        @checkedMeases += meas.name + ";" 

    
    $("<a\>",
      text: "link"
      href: "#/graph/" + @range + "/" + @checkedMeases
      class: "multi-graph-dashboard-link"
    ).appendTo(div)
 
  # render controls and graph
  render: () ->
    @renderCheckboxes()
    @renderLinks()
    
 
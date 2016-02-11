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

    # modes:
    # normal - all measurements every interval
    # history - long amount of time, get only X measurements
    @mode = 'normal'

    # fetched meases
    @meases = []
    # in hash format
    @measesHash = {}

    # fetched settings
    @settings = {}

    # definition of groups
    @measGroups = []

    # which measurements are enabled
    @enabled = {}
    # all fetched data
    @buffer = {}
    # last fetches measurements
    @lastTime = {}
    # which data were processed now
    @processedReady = {}

    # time ranges
    @timeFrom = null
    @timeTo = null
    # amount of seconds represented in graph
    @timeRange = 120 * 1000

    # preselected meases
    # if string occurs there it
    @checkedMeases = null

    # refresh every miliseconds, default value
    @periodicInterval = 4000
    # more inteligent way to calculate interval
    # usable in all systems
    @periodicDynamic = false
    @periodicDynamicMultiplier = 5
    @periodicDynamicMinimum = 2000
    @periodicDynamicMaximum = 10000

    # max amount of measurements fetched when using history mode
    @historyMaxBufferSize = 800
    # if true try use whole time range
    @historyUseFullRange = true
    # if above is set to true, timeFrom will be always stored in variable below
    @historyEarliestTime = 0
    # default time range for history mode
    @historyTimeRange = 12 * 3600 * 1000
    # default interval for refreshing history mode
    @historyInterval = 3600 * 1000

    # offset between server and client in miliseconds
    @serverTimeOffset = 0


    @flotOptions =
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
      xaxis:
        mode: "time"
        timezone: "browser"


  # run everything
  start: () ->
    @getFromApi()

  # helper, current timestamp in miliseconds
  currentTime: () ->
    (new Date()).getTime()


  # gets everything what is important for drawing graphs
  getFromApi: () ->
    $.getJSON "/api/settings.json",  (data) =>
      @settings = data.object
      @calculateInterval()

      $.getJSON "/api/meas_groups.json",  (data) =>
        @measGroups = data.array

        $.getJSON "/api/meas.json",  (data) =>
          @meases = data.array

          # mark client-server time offset
          if @meases.length > 0
            # lower than 0 means time of last measurement from backend is lower than client current time
            @serverTimeOffset = @meases[0].buffer.lastTime - @currentTime()
            console.log "server time offset " + @serverTimeOffset

            # background compat
            if @meases[0].buffer.earliestTime == undefined
              @meases[0].buffer.earliestTime = @meases[0].buffer.lastTime - @meases[0].buffer.count * @meases[0].buffer.interval

              # store earliest time
              @historyEarliestTime = @meases[0].buffer.earliestTime

          # prepare buffers and stuff
          for meas in @meases
            @measesHash[meas.name] = meas
            @buffer[meas.name] = []

          # render controls and graph
          @render()

  # render controls and graph
  render: () ->
    @renderControls()
    @renderGraph()
    setInterval @renderGraph, @periodicInterval

  # some systems are dynamic, some not
  # allow it to use one frontend code to all graphs and all systems
  calculateInterval: () ->
    if @mode == 'history'
      # history mode
      @periodicInterval = @historyInterval

    else
      # normal mode
      if @periodicDynamic
        oldInterval = @periodicInterval
        @periodicInterval = @settings.meas.cycleInterval * @periodicDynamicMultiplier
        @timeRange = @settings.meas.cycleInterval * 1000
        console.log "timeRange set to " + @timeRange

        # some systems are slower or faster
        # this coefficient allow to set timeRange to nature of the system
        if @settings.frontend.currentCoeff
          @timeRange = @timeRange * @settings.frontend.currentCoeff
          console.log "timeRange updated using coefficient to " + @timeRange

        if @periodicInterval < @periodicDynamicMinimum
          @periodicInterval = @periodicDynamicMinimum
        if @periodicInterval > @periodicDynamicMaximum
          @periodicInterval = @periodicDynamicMaximum

        if @periodicInterval != oldInterval
          console.log "interval changed from " + oldInterval + " to " + @periodicInterval


  # meas checkboxes are used to choose what measurements should be displayed
  # it renders also graph container
  renderControls: () =>
    @containerCheckbox = @container + "_checkboxes"
    @containerGraph = @container + "_graph"

    $(@container).addClass("multi-graph-container")

    $("<div\>",
      id: @containerGraph.replace("#","")
      class: "multi-graph-graph-container resizable"
    ).appendTo($(@container))

    $("<div\>",
      id: @containerCheckbox.replace("#","")
      class: "multi-graph-checkbox-container"
    ).appendTo($(@container))

    # meas checkboxes
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

      if is_checked
        # prepare array and start getting data
        @enabled[meas.name] = true
        @buffer[meas.name] = []
        @lastTime[meas.name] = null

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

    # group checkboxes
    for group in @measGroups
      checkboxId = @containerCheckbox.replace("#","") + "_group_" + group.name
      div = $("<div\>",
        class: "multi-graph-group-checkbox-element"
      )

      if @checkedMeases == null
        @checkedMeases = ""

      # not selected is default
      is_checked = false

      # preselected meases are in url
      if (@checkedMeases.indexOf(group.name) > -1)
        is_checked = true

      if is_checked
        for measName in group.measTypes
          # prepare array and start getting data
          @enabled[measName] = true
          @buffer[measName] = []
          @lastTime[measName] = null

      $("<input\>",
        type: "checkbox"
        name: group.name
        id: checkboxId
        checked: is_checked
        class: "multi-graph-group-checkbox"
        "data-meas-group-name": group.name
      ).appendTo(div)

      $("<label>" + group.name + "</label>",
        for: checkboxId
      ).appendTo(div)

      div.appendTo($(@containerCheckbox))


    # dynamically update when checkboxes changed
    $(".multi-graph-checkbox").change (event) =>
      obj = $(event.currentTarget)
      name = obj.data("meas-name")
      @enabled[name] = obj.is(':checked')

      console.log "meas " + name + " is " + @enabled[name]

      # when user disable meas type from graph
      # clean buffer to maintain data when
      # enabling it in future
      if @enabled[name] != true
        @buffer[name] = []
        @lastTime[name] = null

      @renderGraph()

    # dynamically update when group checkboxes changed
    $(".multi-graph-group-checkbox").change (event) =>
      obj = $(event.currentTarget)
      name = obj.data("meas-group-name")
      isEnabled = obj.is(':checked')

      console.log "meas group " + name + " is " + isEnabled

      for group in @measGroups
        if group.name == name
          for measName in group.measTypes
            checkboxTag = $(".multi-graph-checkbox[data-meas-name=" + measName + "]")

            if isEnabled
              checkboxTag.prop('checked', true)
            else
              checkboxTag.prop('checked', false)

            checkboxTag.trigger('change')

    # hax for maximizing graph area
    $(@containerGraph).resize (event) =>
      @plot = null
      @plotGraph()

  urlForMeas: (name, timeFrom, timeTo) =>
    if @mode == "history"
      url = "/api/meas/" + name + "/raw_history_for_time/" + timeFrom + "/" + timeTo + "/" + @historyMaxBufferSize + "/.json"
    else
      # normal
      url = "/api/meas/" + name + "/raw_for_time/" + timeFrom + "/" + timeTo + "/.json"
    return url


  # fetch all needed data to render fresh graph
  renderGraph: () =>
    # set time ranges for current graph
    @timeTo = @currentTime()
    @timeFrom = @timeTo - @timeRange

    # allow to render 0 meas types
    enabledCount = 0

    # fetch all enabled measurement raw data
    for measName in Object.keys(@enabled)
      if @enabled[measName]
        enabledCount += 1

        # history mode update time range
        # to display whole buffer
        if @mode == 'history'
          if @historyUseFullRange
            # use to show from earliest measurement in
            # backend buffer
            @timeRange = @timeTo - @historyEarliestTime
          else
            # use standard time range
            @timeRange = @historyTimeRange

          # update @timeFrom
          @timeFrom = @timeTo - @timeRange

          # and reset lastTime and buffer every time
          @lastTime[measName] = null
          @buffer[measName] = []


        # mark as this meas type is NOT ready
        @processedReady[measName] = false

        # calculate timeFrom
        timeFrom = @timeTo - @timeRange
        if @lastTime[measName]
          if @lastTime[measName] > timeFrom
            timeFrom = @lastTime[measName]

        # add offset
        timeFrom += @serverTimeOffset
        timeTo = @timeTo + @serverTimeOffset


        url = @urlForMeas(measName, timeFrom, timeTo)
        $.getJSON url, (response) =>
          measName = response.meas_type
          length = response.data.length
          i = 0

          # backward compat.
          if response.earliestTime == undefined
            response.earliestTime = response.lastTime - response.count * response.interval
          # update earliest time
          if response.earliestTime > @historyEarliestTime
            @historyEarliestTime = response.earliestTime

          # remove spikes
          if @measesHash[measName].options and @measesHash[measName].options.removeSpikes == 1
            newD = []
            for j in [0..response.data.length] by 1
              nd = 0
              if (response.data[j-1] == undefined) or (response.data[j+1] == undefined)
                nd = response.data[j]
              else
                absA = Math.abs( response.data[j-1] - response.data[j+1] )
                absB = Math.abs( response.data[j-1] - response.data[j] )
                # absC = Math.abs( response.data[j] - response.data[j+1] )

                if (absB > absA * 10.0)
                  console.log "spike at " + j + ": " + response.data[j-1] + " - " + response.data[j] + " - " + response.data[j+1]
                  nd = response.data[j-1]
                else
                  nd = response.data[j]

              newD.push(nd)

            response.data = newD

          for d in response.data
            # convert raw values to [time,value]
            x = (response.lastTime - ((length - i) * response.interval))
            y = ( parseFloat(d) + @measesHash[measName].coefficientOffset ) * @measesHash[measName].coefficientLinear

            i += 1
            @buffer[measName].push [x, y]

          # normalize data after fetch and first process
          oldBuffer = @buffer[measName]
          newBuffer = []

          # only use data in time range
          for d in oldBuffer
            if (d[0] >= @timeFrom) && (d[0] <= @timeTo)
              newBuffer.push d

          # must be sorted to eliminate quirks
          newBuffer = newBuffer.sort((a, b) ->
            a[0] - b[0]
          )

          # replace normalized array
          @buffer[measName] = newBuffer

          # mark last time
          if newBuffer.length > 0
            @lastTime[measName] = newBuffer[newBuffer.length - 1][0]

          # mark as this meas type is ready
          @processedReady[measName] = true

          # render graph if all meas types were fetched and processed
          if @isAllDataReadyToPlot()
            @plotGraph()

    # there is no graph enabled, render empty
    if enabledCount == 0
      @plotGraph()


  isAllDataReadyToPlot: () =>
    ready = true
    for measName in Object.keys(@enabled)
      if @enabled[measName]
        if @processedReady[measName]
          # ok
        else
          ready = false
    return ready


  plotGraph: () =>
    graphData = []
    for measName in Object.keys(@buffer)
      if @enabled[measName]
        measUnit = @measesHash[measName].unit
        graphData.push {"label": measName + " [" + measUnit + "]", "data": @buffer[measName]}

    if @plot
      @plot.setData(graphData)
      @plot.setupGrid();
      @plot.draw()
    else
      @plot = $.plot $(@containerGraph), graphData , @flotOptions

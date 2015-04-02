class @HomeIO
  constructor: ->
    $("#measRefreshLink").click =>
      @updateMeasValues()
      

  reload: () ->
    @getMeasDetails()
  
  clearMeas: () ->
    $("#payload").html("")
  
  registerMeas: (measDetail) =>
    measHtml = "<div class=\"meas\" data-meas=\"" + measDetail["name"] + "\">"
    
    measHtml += "<div class=\"measName\">"
    measHtml += measDetail["name"]
    measHtml += "</div>"

    measHtml += "<div class=\"measValue\">"
    measHtml += measDetail["value"]
    measHtml += "</div>"
    
    measHtml += "</div>"
    $("#payload").append(measHtml)
  
  getMeasDetails: () ->
    @clearMeas
    $.getJSON "/measDetails.json", (data) =>
      for measDetail in data["array"]
        @registerMeas(measDetail)

  updateMeasValues: () ->
    $.getJSON "/measDetails.json", (data) =>
      for measDetail in data["array"]
        $("[data-meas=\"" + measDetail["name"] + "\"] .measValue").html(measDetail["value"])
  
  
    

h = new HomeIO()
h.reload()
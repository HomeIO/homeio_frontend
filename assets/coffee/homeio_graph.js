// Generated by CoffeeScript 1.3.3
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.HomeIOMeasGraph = (function() {

    function HomeIOMeasGraph() {
      this.getRaw = __bind(this.getRaw, this);
      this.buffer = [];
      this.periodicInterval = 2000;
      this.maxBufferSize = 100;
      this.onlyOneRawValue = false;
      this.historyMode = false;
      this.historyLength = 3600 * 1000;
      this.showControls = true;
      this.flot_options = {
        series: {
          lines: {
            show: true,
            fill: true
          },
          points: {
            show: false
          }
        },
        legend: {
          show: true
        },
        grid: {
          clickable: false,
          hoverable: true
        }
      };
    }

    HomeIOMeasGraph.prototype.prepare = function() {
      this.getMeas();
      return this.prepareHtml();
    };

    HomeIOMeasGraph.prototype.prepareHtml = function() {
      if (this.showControls) {
        this.elementContainer = this.element;
        this.elementGraph = "#" + this.meas_name + "_graph";
        this.elementControls = "#" + this.meas_name + "_controls";
        this.elementLastTime = "#" + this.meas_name + "_lastTime";
        $("<div\>", {
          id: this.elementGraph.replace("#", ""),
          style: "width: " + $(this.elementContainer).width() + "px; height: " + $(this.elementContainer).height() + "px"
        }).appendTo(this.elementContainer);
        console.log($(this.elementContainer));
        $("<div\>", {
          id: this.elementControls.replace("#", ""),
          "class": "graph-control"
        }).appendTo(this.elementContainer);
        return $("<div\>", {
          id: this.elementLastTime.replace("#", ""),
          "class": "graph-last-time"
        }).appendTo(this.elementControls);
      } else {
        return this.elementGraph = this.element;
      }
    };

    HomeIOMeasGraph.prototype.currentTime = function() {
      return (new Date()).getTime();
    };

    HomeIOMeasGraph.prototype.timeToString = function(t) {
      var date, formattedTime;
      date = new Date(parseInt(t));
      formattedTime = date.getHours() + ':' + ('0' + date.getMinutes().toString()).slice(-2) + ':' + ('0' + date.getSeconds().toString()).slice(-2);
      return formattedTime;
    };

    HomeIOMeasGraph.prototype.getMeas = function() {
      var _this = this;
      return $.getJSON("/api/meas/" + this.meas_name + "/.json", function(data) {
        _this.meas = data.object;
        _this.interval = _this.meas.buffer.interval;
        _this.getTo = _this.meas.buffer.lastTime;
        _this.getFrom = _this.meas.buffer.lastTime - _this.maxBufferSize * _this.interval;
        _this.localTimeOffset = _this.meas.buffer.lastTime - _this.currentTime();
        _this.getRaw();
        return setInterval(_this.getRaw, _this.periodicInterval);
      });
    };

    HomeIOMeasGraph.prototype.getRaw = function() {
      var url,
        _this = this;
      this.getTo = this.currentTime() + this.localTimeOffset;
      if (this.onlyOneRawValue) {
        url = "/api/meas/" + this.meas.name + "/raw_for_index/0/0/.json";
      } else if (this.historyMode) {
        this.getFrom = this.getTo - this.historyLength;
        url = "/api/meas/" + this.meas.name + "/raw_history_for_time/" + this.getFrom + "/" + this.getTo + "/" + this.maxBufferSize + "/.json";
      } else {
        url = "/api/meas/" + this.meas.name + "/raw_for_time/" + this.getFrom + "/" + this.getTo + "/.json";
      }
      return $.getJSON(url, function(data) {
        _this.getFrom = _this.getTo;
        _this.interval = data.interval;
        _this.lastTime = data.lastTime;
        _this.addToBuffer(data.data);
        _this.renderGraph();
        return _this.afterRender();
      });
    };

    HomeIOMeasGraph.prototype.addToBuffer = function(array) {
      var d, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        d = array[_i];
        if (this.buffer.length >= this.maxBufferSize) {
          this.buffer.shift();
        }
        _results.push(this.buffer.push(d));
      }
      return _results;
    };

    HomeIOMeasGraph.prototype.renderGraph = function() {
      var d, i, new_d, new_data, x, y, _i, _len, _ref;
      new_data = [];
      i = 0;
      _ref = this.buffer;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        d = _ref[_i];
        x = ((i - this.buffer.length) * this.interval) / 1000.0;
        y = (parseFloat(d) + this.meas.coefficientOffset) * this.meas.coefficientLinear;
        new_d = [x, y];
        new_data.push(new_d);
        i += 1;
      }
      new_data = {
        data: new_data,
        color: "#55f",
        label: name
      };
      if (this.plot) {
        this.plot.setData([new_data]);
        this.plot.setupGrid();
        return this.plot.draw();
      } else {
        return this.plot = $.plot($(this.elementGraph), [new_data], this.flot_options);
      }
    };

    HomeIOMeasGraph.prototype.afterRender = function() {
      if (this.elementLastTime) {
        return $(this.elementLastTime).html(this.timeToString(this.lastTime));
      }
    };

    return HomeIOMeasGraph;

  })();

}).call(this);

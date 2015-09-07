// Generated by CoffeeScript 1.9.2
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.HomeIOMeasGraphMulti = (function() {
    function HomeIOMeasGraphMulti() {
      this.plotGraph = bind(this.plotGraph, this);
      this.isAllDataReadyToPlot = bind(this.isAllDataReadyToPlot, this);
      this.renderGraph = bind(this.renderGraph, this);
      this.urlForMeas = bind(this.urlForMeas, this);
      this.renderControls = bind(this.renderControls, this);
      this.container = null;
      this.mode = 'normal';
      this.meases = [];
      this.measesHash = {};
      this.settings = {};
      this.enabled = {};
      this.buffer = {};
      this.lastTime = {};
      this.processedReady = {};
      this.timeFrom = null;
      this.timeTo = null;
      this.timeRange = 120 * 1000;
      this.checkedMeases = null;
      this.periodicInterval = 4000;
      this.periodicDynamic = false;
      this.periodicDynamicMultiplier = 5;
      this.periodicDynamicMinimum = 2000;
      this.periodicDynamicMaximum = 10000;
      this.historyMaxBufferSize = 800;
      this.historyUseFullRange = true;
      this.historyEarliestTime = 0;
      this.historyTimeRange = 12 * 3600 * 1000;
      this.historyInterval = 3600 * 1000;
      this.serverTimeOffset = 0;
      this.flotOptions = {
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
        },
        xaxis: {
          mode: "time",
          timezone: "browser"
        }
      };
    }

    HomeIOMeasGraphMulti.prototype.start = function() {
      return this.getFromApi();
    };

    HomeIOMeasGraphMulti.prototype.currentTime = function() {
      return (new Date()).getTime();
    };

    HomeIOMeasGraphMulti.prototype.getFromApi = function() {
      return $.getJSON("/api/settings.json", (function(_this) {
        return function(data) {
          _this.settings = data.object;
          _this.calculateInterval();
          return $.getJSON("/api/meas.json", function(data) {
            var j, len, meas, ref;
            _this.meases = data.array;
            if (_this.meases.length > 0) {
              _this.serverTimeOffset = _this.meases[0].buffer.lastTime - _this.currentTime();
              console.log("server time offset " + _this.serverTimeOffset);
              if (_this.meases[0].buffer.earliestTime === void 0) {
                _this.meases[0].buffer.earliestTime = _this.meases[0].buffer.lastTime - _this.meases[0].buffer.count * _this.meases[0].buffer.interval;
              }
              _this.historyEarliestTime = _this.meases[0].buffer.earliestTime;
            }
            ref = _this.meases;
            for (j = 0, len = ref.length; j < len; j++) {
              meas = ref[j];
              _this.measesHash[meas.name] = meas;
              _this.buffer[meas.name] = [];
            }
            return _this.render();
          });
        };
      })(this));
    };

    HomeIOMeasGraphMulti.prototype.render = function() {
      this.renderControls();
      this.renderGraph();
      return setInterval(this.renderGraph, this.periodicInterval);
    };

    HomeIOMeasGraphMulti.prototype.calculateInterval = function() {
      var oldInterval;
      if (this.mode === 'history') {
        return this.periodicInterval = this.historyInterval;
      } else {
        if (this.periodicDynamic) {
          oldInterval = this.periodicInterval;
          this.periodicInterval = this.settings.meas.cycleInterval * this.periodicDynamicMultiplier;
          this.timeRange = this.settings.meas.cycleInterval * 1000;
          console.log("timeRange set to " + this.timeRange);
          if (this.settings.frontend.currentCoeff) {
            this.timeRange = this.timeRange * this.settings.frontend.currentCoeff;
            console.log("timeRange updated using coefficient to " + this.timeRange);
          }
          if (this.periodicInterval < this.periodicDynamicMinimum) {
            this.periodicInterval = this.periodicDynamicMinimum;
          }
          if (this.periodicInterval > this.periodicDynamicMaximum) {
            this.periodicInterval = this.periodicDynamicMaximum;
          }
          if (this.periodicInterval !== oldInterval) {
            return console.log("interval changed from " + oldInterval + " to " + this.periodicInterval);
          }
        }
      }
    };

    HomeIOMeasGraphMulti.prototype.renderControls = function() {
      var checkboxId, div, is_checked, j, len, meas, ref;
      this.containerCheckbox = this.container + "_checkboxes";
      this.containerGraph = this.container + "_graph";
      $(this.container).addClass("multi-graph-container");
      $("<div\>", {
        id: this.containerGraph.replace("#", ""),
        "class": "multi-graph-graph-container resizable"
      }).appendTo($(this.container));
      $("<div\>", {
        id: this.containerCheckbox.replace("#", ""),
        "class": "multi-graph-checkbox-container"
      }).appendTo($(this.container));
      ref = this.meases;
      for (j = 0, len = ref.length; j < len; j++) {
        meas = ref[j];
        checkboxId = this.containerCheckbox.replace("#", "") + "_" + meas.name;
        div = $("<div\>", {
          "class": "multi-graph-checkbox-element"
        });
        if (this.checkedMeases === null) {
          this.checkedMeases = "";
        }
        is_checked = false;
        if (this.checkedMeases.indexOf(meas.name) > -1) {
          is_checked = true;
        }
        if (this.checkedMeases === 'default') {
          if (parseInt(meas.priority) > 0) {
            is_checked = true;
          }
        }
        if (is_checked) {
          this.enabled[meas.name] = true;
          this.buffer[meas.name] = [];
          this.lastTime[meas.name] = null;
        }
        $("<input\>", {
          type: "checkbox",
          name: meas.name,
          id: checkboxId,
          checked: is_checked,
          "class": "multi-graph-checkbox",
          "data-meas-name": meas.name
        }).appendTo(div);
        $("<label>" + meas.name + "</label>", {
          "for": checkboxId
        }).appendTo(div);
        div.appendTo($(this.containerCheckbox));
      }
      $(".multi-graph-checkbox").change((function(_this) {
        return function(event) {
          var name, obj;
          obj = $(event.currentTarget);
          name = obj.data("meas-name");
          _this.enabled[name] = obj.is(':checked');
          console.log("meas " + name + " is " + _this.enabled[name]);
          if (_this.enabled[name] !== true) {
            _this.buffer[name] = [];
            _this.lastTime[name] = null;
          }
          return _this.renderGraph();
        };
      })(this));
      return $(this.containerGraph).resize((function(_this) {
        return function(event) {
          _this.plot = null;
          return _this.plotGraph();
        };
      })(this));
    };

    HomeIOMeasGraphMulti.prototype.urlForMeas = function(name, timeFrom, timeTo) {
      var url;
      if (this.mode === "history") {
        url = "/api/meas/" + name + "/raw_history_for_time/" + timeFrom + "/" + timeTo + "/" + this.historyMaxBufferSize + "/.json";
      } else {
        url = "/api/meas/" + name + "/raw_for_time/" + timeFrom + "/" + timeTo + "/.json";
      }
      return url;
    };

    HomeIOMeasGraphMulti.prototype.renderGraph = function() {
      var enabledCount, j, len, measName, ref, timeFrom, timeTo, url;
      this.timeTo = this.currentTime();
      this.timeFrom = this.timeTo - this.timeRange;
      enabledCount = 0;
      ref = Object.keys(this.enabled);
      for (j = 0, len = ref.length; j < len; j++) {
        measName = ref[j];
        if (this.enabled[measName]) {
          enabledCount += 1;
          if (this.mode === 'history') {
            if (this.historyUseFullRange) {
              this.timeRange = this.timeTo - this.historyEarliestTime;
            } else {
              this.timeRange = this.historyTimeRange;
            }
            this.timeFrom = this.timeTo - this.timeRange;
            this.lastTime[measName] = null;
            this.buffer[measName] = [];
          }
          this.processedReady[measName] = false;
          timeFrom = this.timeTo - this.timeRange;
          if (this.lastTime[measName]) {
            if (this.lastTime[measName] > timeFrom) {
              timeFrom = this.lastTime[measName];
            }
          }
          timeFrom += this.serverTimeOffset;
          timeTo = this.timeTo + this.serverTimeOffset;
          url = this.urlForMeas(measName, timeFrom, timeTo);
          $.getJSON(url, (function(_this) {
            return function(response) {
              var d, i, k, l, len1, len2, length, newBuffer, oldBuffer, ref1, x, y;
              measName = response.meas_type;
              length = response.data.length;
              i = 0;
              if (response.earliestTime === void 0) {
                response.earliestTime = response.lastTime - response.count * response.interval;
              }
              if (response.earliestTime > _this.historyEarliestTime) {
                _this.historyEarliestTime = response.earliestTime;
              }
              ref1 = response.data;
              for (k = 0, len1 = ref1.length; k < len1; k++) {
                d = ref1[k];
                x = response.lastTime - ((length - i) * response.interval);
                y = (parseFloat(d) + _this.measesHash[measName].coefficientOffset) * _this.measesHash[measName].coefficientLinear;
                i += 1;
                _this.buffer[measName].push([x, y]);
              }
              oldBuffer = _this.buffer[measName];
              newBuffer = [];
              for (l = 0, len2 = oldBuffer.length; l < len2; l++) {
                d = oldBuffer[l];
                if ((d[0] >= _this.timeFrom) && (d[0] <= _this.timeTo)) {
                  newBuffer.push(d);
                }
              }
              newBuffer = newBuffer.sort(function(a, b) {
                return a[0] - b[0];
              });
              _this.buffer[measName] = newBuffer;
              if (newBuffer.length > 0) {
                _this.lastTime[measName] = newBuffer[newBuffer.length - 1][0];
              }
              _this.processedReady[measName] = true;
              if (_this.isAllDataReadyToPlot()) {
                return _this.plotGraph();
              }
            };
          })(this));
        }
      }
      if (enabledCount === 0) {
        return this.plotGraph();
      }
    };

    HomeIOMeasGraphMulti.prototype.isAllDataReadyToPlot = function() {
      var j, len, measName, ready, ref;
      ready = true;
      ref = Object.keys(this.enabled);
      for (j = 0, len = ref.length; j < len; j++) {
        measName = ref[j];
        if (this.enabled[measName]) {
          if (this.processedReady[measName]) {

          } else {
            ready = false;
          }
        }
      }
      return ready;
    };

    HomeIOMeasGraphMulti.prototype.plotGraph = function() {
      var graphData, j, len, measName, measUnit, ref;
      graphData = [];
      ref = Object.keys(this.buffer);
      for (j = 0, len = ref.length; j < len; j++) {
        measName = ref[j];
        if (this.enabled[measName]) {
          measUnit = this.measesHash[measName].unit;
          graphData.push({
            "label": measName + " [" + measUnit + "]",
            "data": this.buffer[measName]
          });
        }
      }
      if (this.plot) {
        this.plot.setData(graphData);
        this.plot.setupGrid();
        return this.plot.draw();
      } else {
        return this.plot = $.plot($(this.containerGraph), graphData, this.flotOptions);
      }
    };

    return HomeIOMeasGraphMulti;

  })();

}).call(this);

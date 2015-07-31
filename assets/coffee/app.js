// Generated by CoffeeScript 1.9.2
(function() {
  var app;

  app = $.sammy("#main", function() {
    this.use("Haml");
    this.get("#/", function(context) {
      context.app.swap('');
      return context.render("/assets/templates/index.haml").appendTo(context.$element());
    });
    this.get("#/measurements", function(context) {
      return this.load("/api/meas.json").then(function(data) {
        return context.partial("/assets/templates/meas/index.haml", function(html) {
          var i, index, len, meas, ref, results;
          $("#main").html(html);
          ref = data["array"];
          results = [];
          for (index = i = 0, len = ref.length; i < len; index = ++i) {
            meas = ref[index];
            results.push(context.render("/assets/templates/meas/_index_item.haml", {
              meas: meas
            }, function(meas_html) {
              return $("#measArray").append(meas_html);
            }));
          }
          return results;
        });
      });
    });
    this.get("#/graph/:range/:meases", function(context) {
      var subname;
      context.app.swap('');
      subname = 'Multigraph - ' + this.params['range'] + ' seconds range';
      if (this.params['range'] < 0) {
        subname = 'Multigraph - full range';
      }
      return context.render("/assets/templates/multigraph/graph.haml", {
        range: this.params['range'],
        meases: this.params['meases'],
        subname: subname
      }).appendTo(context.$element());
    });
    this.get("#/measurements/:measName", function(context) {
      context.app.swap('');
      return this.load("/api/meas/" + this.params["measName"] + "/.json").then(function(data) {
        var meas;
        meas = data["object"];
        return context.render("/assets/templates/meas/show.haml", {
          meas: meas
        }).appendTo(context.$element());
      });
    });
    this.get("#/measurements/:measName/graph", function(context) {
      context.app.swap('');
      return context.render("/assets/templates/meas/graph_detailed.haml", {
        meas_name: this.params["measName"]
      }).appendTo(context.$element());
    });
    this.get("#/measurements/:measName/history", function(context) {
      context.app.swap('');
      return context.render("/assets/templates/meas/graph_history.haml", {
        meas_name: this.params["measName"]
      }).appendTo(context.$element());
    });
    this.get("#/actions", function(context) {
      return this.load("/api/actions.json").then(function(data) {
        return context.partial("/assets/templates/actions/index.haml", function(html) {
          var action, i, index, len, ref, results;
          $("#main").html(html);
          ref = data["array"];
          results = [];
          for (index = i = 0, len = ref.length; i < len; index = ++i) {
            action = ref[index];
            results.push(context.render("/assets/templates/actions/_index_item.haml", {
              action: action
            }, function(action_html) {
              return $("#actionArray").append(action_html);
            }));
          }
          return results;
        });
      });
    });
    this.get("#/actions/:actionName", function(context) {
      context.app.swap('');
      return this.load("/api/actions/" + this.params["actionName"] + "/.json").then(function(data) {
        var action;
        action = data["object"];
        return context.render("/assets/templates/actions/show.haml", {
          action: action
        }).appendTo(context.$element());
      });
    });
    this.post('#/actions/execute', function(context) {
      $.ajax({
        type: "POST",
        url: "/api/actions/" + this.params["name"] + "/execute.json",
        data: {
          password: md5(this.params['password']),
          name: this.params['name']
        },
        dataType: "JSON"
      }).done(function(executeData) {
        return setTimeout((function() {
          if (executeData.status === 0) {
            $(".action-execute-button").removeClass("pure-button-primary");
            $(".action-execute-button").removeClass("button-error");
            return $(".action-execute-button").addClass("button-success");
          } else {
            $(".action-execute-button").removeClass("pure-button-primary");
            $(".action-execute-button").removeClass("button-success");
            return $(".action-execute-button").addClass("button-error");
          }
        }), 500);
      });
      return context.redirect("#/actions/" + this.params["name"]);
    });
    this.get("#/overseers", function(context) {
      return this.load("/api/overseers.json").then(function(data) {
        return context.partial("/assets/templates/overseers/index.haml", function(html) {
          var i, index, len, overseer, ref, results;
          $("#main").html(html);
          ref = data["array"];
          results = [];
          for (index = i = 0, len = ref.length; i < len; index = ++i) {
            overseer = ref[index];
            results.push(context.render("/assets/templates/overseers/_index_item.haml", {
              overseer: overseer
            }, function(overseer_html) {
              return $("#overseerArray").append(overseer_html);
            }));
          }
          return results;
        });
      });
    });
    this.get("#/overseers/:overseerName", function(context) {
      context.app.swap('');
      return this.load("/api/overseers/" + this.params["overseerName"] + "/.json").then(function(data) {
        var overseer;
        overseer = data["object"];
        return context.render("/assets/templates/overseers/show.haml", {
          overseer: overseer
        }).appendTo(context.$element());
      });
    });
    return this.get("#/stats", function(context) {
      context.app.swap('');
      return this.load("/api/stats.json").then(function(data) {
        var stats;
        stats = data["object"];
        return context.render("/assets/templates/stats/show.haml", {
          stats: stats
        }).appendTo(context.$element());
      });
    });
  });

  $(function() {
    app.run("#/");
    $(window).resize((function(_this) {
      return function(event) {
        if ($.data(_this, "resizeBlock") !== true) {
          $.data(_this, "resizeBlock", true);
          clearTimeout($.data(_this, "resizeTimer"));
          return $.data(_this, "resizeTimer", setTimeout(function() {
            var element, h, ih, innerObj, oh, paddingTop;
            h = event.currentTarget.innerHeight;
            $('body').height(h);
            $('#layout').height(h);
            $('.content').height(h);
            innerObj = $(".content-inner");
            if (innerObj) {
              element = innerObj.get(0);
              paddingTop = 60;
              oh = element.offsetTop - element.scrollTop + element.clientTop + paddingTop;
              ih = h - oh;
              if (h > 200) {
                $('.content-inner').height(ih);
              }
            }
            $('.resizable').trigger('resize');
            return $.data(_this, "resizeBlock", false);
          }, 100));
        }
      };
    })(this));
    return setTimeout((function(_this) {
      return function() {
        return $(window).trigger('resize');
      };
    })(this), 20);
  });

}).call(this);

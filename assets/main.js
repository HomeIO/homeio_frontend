// Generated by CoffeeScript 1.3.3
(function() {
  var app;

  app = $.sammy("#main", function() {
    this.use("Haml");
    this.get("#/", function(context) {
      context.app.swap('');
      return context.render("/assets/templates/index.haml").appendTo(context.$element());
    });
    this.get("#/measurements", function(context) {
      return this.load("/measDetails.json").then(function(data) {
        var index, meas, _i, _len, _ref, _results;
        context.app.swap('');
        _ref = data["array"];
        _results = [];
        for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
          meas = _ref[index];
          _results.push(context.render("/assets/templates/meas.haml", {
            meas: meas,
            index: index
          }).appendTo(context.$element()));
        }
        return _results;
      });
    });
    return this.get("#/measurements/:measName", function(context) {
      context.app.swap('');
      return context.log(this.params['measName']);
    });
  });

  $(function() {
    return app.run("#/");
  });

}).call(this);

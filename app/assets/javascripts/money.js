var Money = {
  dollars: function(cents, keepNegative) {
    cents = keepNegative ? cents : Math.abs(cents);
    return (cents / 100).toFixed(2);
  },

  parse: function(field, keepNegative) {
    return Money.parseValue($F(field), keepNegative);
  },

  /* don't want to use parseFloat, because we can be subject to
   * floating point round-off */
  parseValue: function(string, keepNegative) {
    var value = string.gsub(/[^-+\d.]/, "");
    var match = value.match(/^([-+]?)(\d*)(?:\.(\d*))?$/);

    if(!match) return 0;

    var sign = ((match[1] == "-") && keepNegative) ? -1 : 1;
    if(match[2].length > 0)
      var dollars = parseInt(match[2]);
    else
      var dollars = 0;

    if(match[3] && match[3].length > 0) {
      var cents_magnitude = Math.pow(10, match[3].length);
      var cents_text = match[3].sub(/^0+/, "");
      if(cents_text.blank()) cents_text = "0";
      var cents = Math.round(parseInt(cents_text) * 100 / cents_magnitude);
    } else {
      var cents = 0;
    }

    return sign * (dollars * 100 + cents);
  },

  format: function(field) {
    return Money.formatValue(Money.parse(field, true));
  },

  formatValue: function(cents) {
    var sign = cents < 0 ? -1 : 1;
    var source = String(Math.abs(cents));
    var result;

    if(source.length > 2) {
      result = "." + source.slice(-2);
      source = source.slice(0,-2);
    } else if(source.length == 2) {
      result = "." + source;
      source = "";
    } else if(source.length == 1) {
      result = ".0" + source;
      source = "";
    } else {
      result = ".00";
    }

    while(source.length > 3) {
      result = "," + source.slice(-3) + result;
      source = source.slice(0,-3);
    }

    if(source.length > 0) {
      result = source + result;
    } else if(result[0] == ".") {
      result = "0" + result;
    }

    if(sign < 0) {
      result = "-" + result;
    }

    return result;
  }
}

var Money = {
  dollars: function(cents) {
    return (Math.abs(cents) / 100).toFixed(2);
  },

  parse: function(field, keepNegative) {
    return Money.parseValue($F(field));
  },

  /* don't want to use parseFloat, because we can be subject to
   * floating point round-off */
  parseValue: function(string, keepNegative) {
    var value = string.gsub(/[^-+\d.]/, "");
    var match = value.match(/^([-+]?)(\d*)(?:\.(\d+))?$/);

    if(!match) return 0;

    var sign = (match[1] == "-" && keepNegative) ? -1 : 1;
    if(match[2].length > 0)
      var dollars = parseInt(match[2]);
    else
      var dollars = 0;

    if(match[3] && match[3].length > 0) {
      var cents_magnitude = Math.pow(10, match[3].length);
      var cents = Math.round(parseInt(match[3].sub(/^0+/, "")) * 100 / cents_magnitude);
    } else {
      var cents = 0;
    }

    return sign * (dollars * 100 + cents);
  }
}

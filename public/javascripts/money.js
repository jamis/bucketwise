var Money = {
  dollars: function(cents) {
    return (Math.abs(cents) / 100).toFixed(2);
  },

  cents: function(dollars) {
    return Math.floor(Math.abs(dollars) * 100);
  },

  parse: function(field, keepNegative) {
    var value = $F(field).gsub(/[^-+\d.]/, "");
    var raw = parseFloat(value);
    var sign = 1;

    if(raw < 0 && keepNegative) sign = -1;

    var result = Money.cents(raw);
    return isNaN(result) ? 0 : (sign * result);
  }
}

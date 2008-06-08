var Money = {
  dollars: function(cents) {
    return (Math.abs(cents) / 100).toFixed(2);
  },

  cents: function(dollars) {
    return Math.floor(Math.abs(dollars) * 100);
  },

  parse: function(field) {
    var result = Money.cents(parseFloat($F(field)));
    return isNaN(result) ? 0 : result;
  }
}
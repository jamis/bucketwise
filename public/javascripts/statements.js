var Statements = {
  clickItem: function(id) {
    $('check_account_item_' + id).click();
  },

  toggleCleared: function(id) {
    var checked = $('check_account_item_' + id).checked;
    var amount = parseInt($('amount_account_item_' + id).innerHTML);
    var subtotalField = $('account_item_' + id).up('fieldset').down('.subtotal_dollars');
    var subtotal = Money.parseValue(subtotalField.innerHTML, true);

    if(checked) {
      $('account_item_' + id).addClassName('cleared');
      subtotalField.innerHTML = "$" + Money.formatValue(subtotal + amount);
    } else {
      $('account_item_' + id).removeClassName('cleared');
      subtotalField.innerHTML = "$" + Money.formatValue(subtotal - amount);
    }

    Statements.updateBalances();
  },

  startingBalance: function() {
    if(!Statements.cachedBalance)
      Statements.cachedBalance = Money.parseValue($('starting_balance').innerHTML, true);
    return Statements.cachedBalance;
  },

  endingBalance: function() {
    return Money.parse($('statement_ending_balance'), true);
  },

  settled: function() {
    return $$('.subtotal_dollars').inject(0, function(sum, span) {
      return sum + Money.parseValue(span.innerHTML, true);
    });
  },

  remaining: function() {
    return Statements.startingBalance() + Statements.settled() - Statements.endingBalance();
  },

  updateBalances: function() {
    var ending = $('statement_ending_balance');
    ending.value = Money.format(ending);

    var remaining = Statements.remaining();
    var remainingText = Money.formatValue(remaining);

    ['deposits', 'checks', 'expenses'].each(function(section) {
      if($(section)) {
        var span = $$("#" + section + " .remaining_dollars").first();

        if(remaining == 0)
          span.addClassName("balanced");
        else
          span.removeClassName("balanced");

        span.innerHTML = "$" + remainingText;
      }
    })

    if(remaining == 0) {
      $('balanced').show();
      $('actions').hide();
    } else {
      $('balanced').hide();
      $('actions').show();
    }
  }
}

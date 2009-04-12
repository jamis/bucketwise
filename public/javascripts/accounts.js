var Accounts = {
  revealForm: function() {
    if($('blankslate')) {
      $('blankslate').hide();
    } else {
      $('data').hide();
      $('links').hide();
    }

    $('new_account').show();
    $('account_name').activate();
  },

  hideForm: function() {
    if(Accounts.origin) {
      window.location = Accounts.origin;
    } else {
      Accounts.reset();
      $('new_account').hide();

      if($('blankslate')) {
        $('blankslate').show();
      } else {
        $('data').show();
        $('links').show();
      }
    }
  },

  submit: function() {
    if($F('account_name').blank()) {
      $('account_name').activate();
      alert('Please provide a name for the account.');
      return false;
    }

    var balance = Money.parse('current_balance', true);
    $('account_starting_balance_amount').value = balance;

    return true;
  },

  reset: function() {
    $('new_account_form').reset();
  },

  rename: function(url, name, token) {
    new_name = prompt("Enter the name for this account:", name);
    if(new_name && new_name != name) {
      params = encodeURIComponent("account[name]") + "=" + encodeURIComponent(new_name) +
        "&authenticity_token=" + encodeURIComponent(token);

      new Ajax.Request(url, {
        asynchronous:true,
        evalScripts:true,
        method:'put',
        parameters:params
      });
    }
  }
}

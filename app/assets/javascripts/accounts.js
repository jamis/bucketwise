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

    if($F('account_role') == 'credit-card' && $F('account_limit').blank()) {
      $('account_name').activate();
      alert('Please provide a limit for the account.');
      return false;
    }

    var balance = Money.parse('current_balance', true);
    $('account_starting_balance_amount').value = balance;

    var limit = Money.parse('account_limit', true);
    $('account_limit').value = limit;

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
  },

  adjustLimit: function(url, limit, token) {
    new_limit = prompt("Enter the new limit for this account:", Money.formatValue(limit));
    new_limit = Money.parseValue(new_limit);
    while(new_limit == '') {
      new_limit = prompt("Cannot have have a blank limit. Please re-enter it:", Money.formatValue(limit));
    }
    if(new_limit && new_limit != limit) {
      params = encodeURIComponent("account[limit]") + "=" + encodeURIComponent(new_limit) +
        "&authenticity_token=" + encodeURIComponent(token);

      new Ajax.Request(url, {
        asynchronous:true,
        evalScripts:true,
        method:'put',
        parameters:params,
        onSuccess: function(request) {
          window.location.reload();
        }
      });
    }
  },

  showOrHideCreditLimit: function(value) {
    if (value == 'credit-card') {
      Accounts.showCreditLimit();
    } else {
      Accounts.hideCreditLimit();
    }
  },

  showCreditLimit: function() {
    $('credit_limit_div').show();
  },

  hideCreditLimit: function() {
    $('credit_limit_div').hide();
  }
}

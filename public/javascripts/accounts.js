var Accounts = {
  revealForm: function() {
    $('accounts_summary').hide();
    $('accounts_summary_header').addClassName('anchor');
    $('new_account').show();
    $('account_name').activate();
  },

  hideForm: function() {
    Accounts.reset();
    $('new_account').hide();
    $('accounts_summary_header').removeClassName('anchor');
    $('accounts_summary').show();
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
  }
}

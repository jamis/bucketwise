var Events = {
  selectPaymentType: function() {
    $('check_options').hide();
    $('credit_options').hide();

    select = $('event_payment_method');
    switch(select.options[select.selectedIndex].value) {
      case 'check':
        $('check_options').show();
        break;
      case 'credit':
        $('credit_options').show();
        break;
    }
  },

  updateBucketsFor: function(select, section, selected) {
    var bucketSelect = $('bucket_for_' + section);
    for(var i = 0; i < bucketSelect.options.length; i++) {
      bucketSelect.options[0] = null;
    }

    if(select.selectedIndex == 0) {
      bucketSelect.disabled = true;
      bucketSelect.options[0] = new Option("-- Select an account --", "");
    } else {
      bucketSelect.disabled = false;

      i = 0;
      var acctId = parseInt(select.options[select.selectedIndex].value);
      Events.buckets[acctId].each(function(option) {
        bucketSelect.options[i++] = new Option(option[0], option[1]);
      })

      bucketSelect.options[i++] = new Option("-- More than one --", "+")
      bucketSelect.options[i++] = new Option("-- Add a new bucket --", "++")

      if(selected) {
        for(i = 0; i < bucketSelect.options.length; i++) {
          if(bucketSelect.options[i].value == selected) {
            bucketSelect.selectedIndex = i;
            break;
          }
        }
      }
    }
  },

  handleBucketChange: function(select, section) {
    var selected = select.options[select.selectedIndex].value;

    if(selected == '+') {
      $(section + '.multiple_buckets').show();
      $(section + '.single_bucket').hide();

    } else if(selected == '++') {
      var acctSelect = $('account_for_' + section);
      var acctId = parseInt(acctSelect.options[acctSelect.selectedIndex].value);

      var name = prompt('Name your new bucket:');
      var value = "!" + name;
      Events.buckets[acctId].push([name, value]);
      Events.updateBucketsFor(acctSelect, section, value);
    }
  }
}
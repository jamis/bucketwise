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

  updateBucketsFor: function(section, selected) {
    var acctSelect = $('account_for_' + section);
    var bucketSelects = $$('.bucket_for_' + section);

    bucketSelects.each(function(bucketSelect) {
      for(var i = 0; i < bucketSelect.options.length; i++) {
        bucketSelect.options[0] = null;
      }

      if(acctSelect.selectedIndex == 0) {
        bucketSelect.disabled = true;
        bucketSelect.options[0] = new Option("-- Select an account --", "");
      } else {
        bucketSelect.disabled = false;

        i = 0;
        var acctId = parseInt(acctSelect.options[acctSelect.selectedIndex].value);
        Events.accounts[acctId].buckets.each(function(bucket) {
          bucketSelect.options[i++] = new Option(bucket.name, bucket.id);
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
    });
  },

  handleAccountChange: function(select, section) {
    $(section + '.multiple_buckets').hide();
    $(section + '.single_bucket').show();

    Events.updateBucketsFor(section);

    if(section == 'payment_source') {
      $('check_options').hide();
      $('credit_options').hide();

      if(select.selectedIndex > 0) {
        var acctId = parseInt(select.options[select.selectedIndex].value);
        var account = Events.accounts[acctId];

        switch(account.role) {
          case 'credit-card':
            $('credit_options').show();
            break;
          case 'checking':
            $('check_options').show();
            break;
        }
      }
    }
  },

  handleBucketChange: function(select, section) {
    var selected = select.options[select.selectedIndex].value;

    if(selected == '+') {
      Events.addLineItemTo(section);
      Events.addLineItemTo(section);
      $(section + '.multiple_buckets').show();
      $(section + '.single_bucket').hide();

    } else if(selected == '++') {
      var acctSelect = $('account_for_' + section);
      var acctId = parseInt(acctSelect.options[acctSelect.selectedIndex].value);

      var name = prompt('Name your new bucket:');
      var value = "!" + name;
      Events.accounts[acctId].buckets.push({'id':value,'name':name});
      Events.updateBucketsFor(section, value);
    }
  },

  addLineItemTo: function(section) {
    var ol = $(section + ".line_items");
    var li = document.createElement("li");
    li.innerHTML = $('template.' + section).innerHTML;
    ol.appendChild(li);
  }
}
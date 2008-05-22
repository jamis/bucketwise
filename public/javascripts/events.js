var Events = {
  updateBucketsFor: function(section, reset) {
    var acctSelect = $('account_for_' + section);

    Events.getBucketSelects(section).each(function(bucketSelect) {
      var selected = bucketSelect.options[bucketSelect.selectedIndex].value;
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

        if(bucketSelect.hasClassName("splittable")) {
          bucketSelect.options[i++] = new Option("-- More than one --", "+")
        }

        bucketSelect.options[i++] = new Option("-- Add a new bucket --", "++")
        if(!reset) Events.selectBucket(bucketSelect, selected);
      }
    });
  },

  handleAccountChange: function(select, section) {
    $(section + '.multiple_buckets').hide();
    $(section + '.line_items').innerHTML = "";
    $(section + '.single_bucket').show();

    Events.updateBucketsFor(section, true);

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
      Events.updateBucketsFor(section);

    } else if(selected == '++') {
      var acctSelect = $('account_for_' + section);
      var acctId = parseInt(acctSelect.options[acctSelect.selectedIndex].value);

      var name = prompt('Name your new bucket:');
      var value = "!" + name;
      Events.accounts[acctId].buckets.push({'id':value,'name':name});
      Events.updateBucketsFor(section);
      Events.selectBucket(select, value);
    }
  },

  selectBucket: function(select, value) {
    for(var i = 0; i < select.options.length; i++) {
      if(select.options[i].value == value) {
        select.selectedIndex = i;
        break;
      }
    }
  },

  getBucketSelects: function(section) {
    return $$('#' + section + ' select.bucket_for_' + section);
  },

  addLineItemTo: function(section) {
    var ol = $(section + ".line_items");
    var li = document.createElement("li");
    li.innerHTML = $('template.' + section).innerHTML;
    ol.appendChild(li);
  }
}
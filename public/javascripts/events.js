var Events = {
  updateBucketsFor: function(section, reset) {
    var acctSelect = $('account_for_' + section);
    var disabled = acctSelect.selectedIndex == 0;
    var acctId = disabled ? null : parseInt(acctSelect.options[acctSelect.selectedIndex].value);

    Events.getBucketSelects(section).each(function(bucketSelect) {
      Events.populateBucket(bucketSelect, acctId, {'reset':reset, 'disabled':disabled});
    });
  },

  populateBucket: function(select, acctId, options) {
    options = options || {};

    var selected = select.options[select.selectedIndex].value;
    for(var i = 0; i < select.options.length; i++) {
      select.options[0] = null;
    }

    if(options['disabled']) {
      select.disabled = true;
      select.options[0] = new Option("-- Select an account --", "");
    } else {
      select.disabled = false;

      i = 0;
      Events.accounts[acctId].buckets.each(function(bucket) {
        select.options[i++] = new Option(bucket.name, bucket.id);
      })

      if(select.hasClassName("splittable")) {
        select.options[i++] = new Option("-- More than one --", "+");
      }

      select.options[i++] = new Option("-- Add a new bucket --", "++");
      if(!options['reset']) Events.selectBucket(select, selected);
    }
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

  bucketComparer: function(a, b) {
    if(a.name == b.name) return 0;
    if(a.name < b.name) return -1;
    return 1;
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
      if(name) {
        var value = "!" + name;
        Events.accounts[acctId].buckets.push({'id':value,'name':name});
        Events.accounts[acctId].buckets.sort(Events.bucketComparer);
        Events.updateBucketsFor(section);
        Events.selectBucket(select, value);
      } else {
        select.selectedIndex = 0;
      }
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

  addLineItemTo: function(section, populate) {
    var ol = $(section + ".line_items");
    var li = document.createElement("li");
    li.innerHTML = $('template.' + section).innerHTML;
    ol.appendChild(li);
    if(populate) {
      var acctSelect = $('account_for_' + section);
      var acctId = parseInt(acctSelect.options[acctSelect.selectedIndex].value);
      Events.populateBucket(li.down("select"), acctId);
    }
  },

  removeLineItem: function(li) {
    li.remove();
    Events.updateUnassigned();
  },

  updateUnassigned: function() {
    Events.updateUnassignedFor('payment_source');
    Events.updateUnassignedFor('credit_options');
  },

  computeUnassignedFor: function(section) {
    var total = Money.parse('expense_total');
    var unassigned = total;

    var line_items = $(section + ".line_items");
    line_items.select("input[type=text]").each(function(field) {
      var value = Money.parse(field);
      unassigned -= value;
    });

    return { 'total': total, 'unassigned': unassigned };
  },

  updateUnassignedFor: function(section) {
    var money = Events.computeUnassignedFor(section)

    if(money.unassigned > 0) {
      $(section + ".unassigned").innerHTML = "<strong>$" + Money.dollars(money.unassigned) + "</strong> of $" + Money.dollars(money.total) + " remains unallocated.";
    } else if(money.unassigned < 0) {
      $(section + ".unassigned").innerHTML = "You've overallocated <strong>$" + Money.dollars(money.unassigned) + "</strong>.";
    } else {
      $(section + ".unassigned").innerHTML = "";
    }
  },

  buildQueryStringFor: function(request) {
    var qs = "";

    $H(request).each(function(pair) {
      if(qs.length > 0) qs += "&";

      if(pair.value && typeof pair.value == "object") {
        n = 0;
        pair.value.each(function(item) {
          $H(item).each(function(ipair) {
            if(qs.length > 0) qs += "&";
            qs += encodeURIComponent(pair.key + "[" + n + "][" + ipair.key + "]") + "=" +
              encodeURIComponent(ipair.value);
          });
          n++;
        });
      } else {
        qs += encodeURIComponent(pair.key) + "=" + encodeURIComponent(pair.value);
      }
    });

    return qs;
  },

  serialize: function(parent) {
    var request = new Hash();

    request.set('event[account_items]', []);
    request.set('event[bucket_items]', []);

    Events.serializeAuthenticityToken(request);

    if($('event_check_number').visible()) {
      request.set('event[check_number]', $F('event_check_number'));
    }

    Events.serializeGeneralInformation(request);
    Events.serializeSection(request, 'payment_source');

    if($('credit_options').visible()) {
      Events.serializeSection(request, 'credit_options', {skip_account_item: true});
      var account_id = parseInt($F('account_for_credit_options'));
      var debit = Money.parse('expense_total');
      Events.addBucketItem(request, account_id, Events.accounts[account_id]['aside'], debit, 'aside');
    }

    return Events.buildQueryStringFor(request);
  },

  serializeAuthenticityToken: function(request) {
    var field = $('event_form').down('input[name=authenticity_token]');
    request.set('authenticity_token', $F(field));
  },

  serializeGeneralInformation: function(request) {
    Form.getElements('general_information').each(function(field) {
      if(!field.name.blank()) request.set(field.name, field.value);
    });
  },

  serializeSection: function(request, section, options) {
    options = options || {};
    var account_id = $F('account_for_' + section);
    var expense = -Money.parse('expense_total');

    if(!options['skip_account_item']) {
      Events.addAccountItem(request, account_id, expense);
    }

    if($(section + '.single_bucket').visible()) {
      var bucket_id = $F($(section + '.single_bucket').down('select'));
      Events.addBucketItem(request, account_id, bucket_id, expense, section);
    } else {
      Events.addBucketLineItems(request, account_id, section);
    }
  },

  addAccountItem: function(request, account_id, amount) {
    var item = { account_id: account_id, amount: amount };
    Events.appendValue(request, 'event[account_items]', item);
  },

  addBucketItem: function(request, account_id, bucket_id, amount, role) {
    var item = { account_id: account_id, bucket_id: bucket_id, amount: amount, role: role };
    Events.appendValue(request, 'event[bucket_items]', item);
  },

  appendValue: function(request, key, value) {
    request.get(key).push(value);
  },

  addBucketLineItems: function(request, account_id, section) {
    $(section + '.line_items').select('li').each(function(row) {
      bucket_id = $F(row.down('select'));
      amount = -Money.parse(row.down('input[type=text]'));
      Events.addBucketItem(request, account_id, bucket_id, amount, section);
    });
  },

  submit: function(form) {
    try {
      // FIXME: validations!

      var options = {};
      var action = form.readAttribute('action');

      options.parameters = Events.serialize(form);

      if (form.hasAttribute('method') && !options.method)
        options.method = form.method;

      return new Ajax.Request(action, options);
    } catch(e) {
      alert(e);
    }
  },

  revealExpenseForm: function() {
    $('links').hide();
    $('data').hide();
    $('new_expense').show();
  },

  cancel: function() {
    $('event_form').reset();

    Events.handleAccountChange($('account_for_credit_options'), 'credit_options');
    Events.handleAccountChange($('account_for_payment_source'), 'payment_source');

    $('new_expense').hide();
    $('data').show();
    $('links').show();
  },

  expand: function(id) {
    $('expand_event_' + id).className = "expanding";
    $('event_' + id).addClassName('zoomed');
  },

  expanded: function(id) {
    $('expand_event_' + id).className = "expanded";
  },

  collapse: function(id) {
    $('expand_event_' + id).className = "expand";
    $('event_' + id).removeClassName('zoomed');
    $('zoomed_event_' + id).remove();
  }
}

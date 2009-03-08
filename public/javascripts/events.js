var Events = {
  updateBucketsFor: function(section, reset) {
    var acctSelect = $('account_for_' + section);
    var disabled = acctSelect.selectedIndex == 0;
    var acctId = disabled ? null : parseInt(acctSelect.options[acctSelect.selectedIndex].value);
    var skipAside = section == 'credit_options';

    Events.getBucketSelects(section).each(function(bucketSelect) {
      Events.populateBucket(bucketSelect, acctId,
        {'reset':reset, 'disabled':disabled, 'skipAside':skipAside});
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
        if(bucket.role != 'aside' || !options.skipAside) {
          select.options[i++] = new Option(bucket.name, bucket.id);
        }
      })

      if(select.hasClassName("splittable")) {
        select.options[i++] = new Option("-- More than one --", "+");
      }

      select.options[i++] = new Option("-- Add a new bucket --", "++");
      if(!options['reset']) Events.selectBucket(select, selected);
    }
  },

  sectionWantsCreditOptions: function(section) {
    return section == 'payment_source';
  },

  sectionWantsCheckOptions: function(section) {
    return (section == 'payment_source' || section == 'transfer_from' || section == 'deposit');
  },

  handleAccountChange: function(select, section) {
    $(section + '.multiple_buckets').hide();
    $(section + '.line_items').innerHTML = "";
    $(section + '.single_bucket').show();

    Events.updateBucketsFor(section, true);

    if(Events.sectionWantsCreditOptions(section)) $('credit_options').hide();
    if(Events.sectionWantsCheckOptions(section)) $(section + '.check_options').hide();

    if(select.selectedIndex > 0) {
      var acctId = parseInt(select.options[select.selectedIndex].value);
      var account = Events.accounts[acctId];

      switch(account.role) {
        case 'credit-card':
          if(Events.sectionWantsCreditOptions(section))
            $('credit_options').show();
          break;
        case 'checking':
          if(Events.sectionWantsCheckOptions(section))
            $(section + '.check_options').show();
          break;
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
      $(section + '.multiple_buckets').down('input').activate();

    } else if(selected == '++') {
      var acctSelect = $('account_for_' + section);
      var acctId = parseInt(acctSelect.options[acctSelect.selectedIndex].value);

      var name = prompt('Name your new bucket:');
      if(name) {
        // FIXME: make sure 'name' is not empty, and is not already taken
        var value = "n:" + name;
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
      Events.populateBucket(li.down("select"), acctId,
        {'skipAside':(section=='credit_options')});
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

  buildXMLStringFor: function(request) {
    var xml = "";

    for(var key in request) {
      tag = key.replace("_", "-");
      xml += Events.buildXMLFor(tag, request[key]);
    }

    return xml;
  },

  buildXMLFor: function(tag, value) {
    var xml = "";

    if(Object.isArray(value)) {
      xml += "<" + tag + "s type='array'>";
      value.each(function(element) {
        xml += Events.buildXMLFor(tag, element);
      });
      xml += "</" + tag + "s>";
    } else if(typeof value == "object") {
      xml += "<" + tag + ">" + Events.buildXMLStringFor(value) + "</" + tag + ">";
    } else {
      xml += "<" + tag + ">" + value + "</" + tag + ">";
    }

    return xml;
  },

  serialize: function(parent) {
    var request = {};

    request['event'] = {};
    request['event']['line_item'] = [];

    Events.serializeGeneralInformation(request);

    if($('payment_source').visible()) {
      Events.serializeSection(request, 'payment_source', {expense:true});
    }

    if($('credit_options').visible()) {
      Events.serializeSection(request, 'credit_options', {expense:true});
      var account_id = parseInt($F('account_for_credit_options'));
      var debit = Money.parse('expense_total');
      Events.addLineItem(request, account_id, 'r:aside', debit, 'aside');
    }

    if($('deposit').visible()) {
      Events.serializeSection(request, 'deposit', {expense:false})
    }

    if($('transfer_from').visible()) {
      Events.serializeSection(request, 'transfer_from', {expense:true})
    }

    if($('transfer_to').visible()) {
      Events.serializeSection(request, 'transfer_to', {expense:false})
    }

    return request;
  },

  addToRequest: function(request, name, value) {
    if(name.match(/^\w+$/)) {
      request[name] = value;
    } else {
      var parts = name.replace("][", ",").replace("[", ",").replace("]", "").split(/,/);
      var n = 0;

      while(n < parts.length-1) {
        var part = parts[n];
        request[part] = request[part] || {};
        request = request[part];
        n++;
      }

      request[parts[n]] = value;
    }
  },

  serializeGeneralInformation: function(request) {
    Form.getElements('general_information').each(function(field) {
      if(!field.name.blank() && field.name != "amount")
        Events.addToRequest(request, field.name, field.value);
    });
  },

  serializeSection: function(request, section, options) {
    options = options || {};
    var account_id = $F('account_for_' + section);
    var expense = (options.expense ? -1 : 1) * Money.parse('expense_total');

    if(Events.sectionWantsCheckOptions(section) && $(section + '.check_options').visible()) {
      request['event']['check_number'] = $F($(section + '.check_options').down('input'));
    }

    if($(section + '.single_bucket').visible()) {
      var bucket_id = $F($(section + '.single_bucket').down('select'));
      Events.addLineItem(request, account_id, bucket_id, expense, section);
    } else {
      Events.addLineItems(request, account_id, section, options);
    }
  },

  addLineItem: function(request, account_id, bucket_id, amount, role) {
    var item = { account_id: account_id, bucket_id: bucket_id, amount: amount, role: role };
    request['event']['line_item'].push(item);
  },

  addLineItems: function(request, account_id, section, options) {
    options = options || {};
    $(section + '.line_items').select('li').each(function(row) {
      bucket_id = $F(row.down('select'));
      amount = (options.expense ? -1 : 1) * Money.parse(row.down('input[type=text]'));
      Events.addLineItem(request, account_id, bucket_id, amount, section);
    });
  },

  submit: function(form) {
    try {
      // FIXME: validations!

      var options = {};
      var action = form.readAttribute('action');

      options.postBody = Events.buildXMLStringFor(Events.serialize(form));

      if (form.hasAttribute('method') && !options.method)
        options.method = form.method;

      options.contentType = "application/xml";

      return new Ajax.Request(action, options);
    } catch(e) {
      alert(e);
    }
  },

  revealBasicForm: function() {
    $('links').hide();
    $('new_event').show();
    $$('.expense_label').invoke('hide');
    $$('.deposit_label').invoke('hide');
    $$('.transfer_label').invoke('hide');
    $('payment_source').hide();
    $('credit_options').hide();
    $('deposit').hide();
    $('transfer_from').hide();
    $('transfer_to').hide();
  },

  revealExpenseForm: function() {
    Events.revealBasicForm();
    $$('.expense_label').invoke('show');
    $('payment_source').show();
  },

  revealDepositForm: function() {
    Events.revealBasicForm();
    $$('.deposit_label').invoke('show');
    $('deposit').show();
  },

  revealTransferForm: function() {
    Events.revealBasicForm();
    $$('.transfer_label').invoke('show');
    $('transfer_from').show();
    $('transfer_to').show();
  },

  reset: function() {
    $('event_form').reset();

    ['credit_options', 'payment_source', 'deposit', 'transfer_from', 'transfer_to'].each(
      function(section) {
        Events.handleAccountChange($('account_for_' + section), section);
      })
  },

  cancel: function() {
    Events.reset();
    $('new_event').hide();
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

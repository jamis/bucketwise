var Events = {
  nextID: 0,

  updateBucketsFor: function(section, reset) {
    var skipAside = section == 'credit_options';
    var acctField = $('account_for_' + section);
    var disabled = acctField.tagName == "SELECT" && $F(acctField).empty();
    var acctId = disabled ? null : $F(acctField);

    Events.getBucketSelects(section).each(function(bucketSelect) {
      Events.populateBucket(bucketSelect, acctId,
        {'reset':reset, 'disabled':disabled, 'skipAside':skipAside});
    });
  },

  populateBucket: function(select, acctId, options) {
    options = options || {};

    var selected = undefined;
    if(select.selectedIndex >= 0)
      selected = select.options[select.selectedIndex].value;

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

    if(Events.sectionWantsCreditOptions(section)) {
      $(section + '.repayment_options').hide();
      $('credit_options').hide();
    }

    if(Events.sectionWantsCheckOptions(section)) $(section + '.check_options').hide();

    if(!$F(select).empty()) {
      var acctId = parseInt(select.options[select.selectedIndex].value);
      var account = Events.accounts[acctId];

      switch(account.role) {
        case 'credit-card':
          if(Events.sectionWantsCreditOptions(section))
            $(section + '.repayment_options').show();
          break;
        case 'checking':
          if(Events.sectionWantsCheckOptions(section))
            $(section + '.check_options').show();
          break;
      }
    }
  },

  showRepaymentOptions: function(section) {
    $(section + '.repayment_options').hide();
    $('credit_options').show();
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
      var acctId = $F('account_for_' + section);

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
    var input = li.down("input");
    if(populate) {
      var acctSelect = $('account_for_' + section);
      var acctId = $F('account_for_' + section);
      var bucketSelect = li.down("select");
      Events.populateBucket(bucketSelect, acctId,
        {'skipAside':(section=='credit_options')});
      if(populate != true) {
        bucketSelect.setValue(populate.bucket_id);
        input.setValue(Money.formatValue(Math.abs(populate.amount)));
      }
    }
    input.focus();
  },

  removeLineItem: function(li) {
    li.remove();
    Events.updateUnassigned();
  },

  addTaggedItem: function(item) {
    var ol = $('tagged_items');
    var li = document.createElement("li");
    var content = $('template.tags').innerHTML;
    var id = "tagged_item_i" + String(Events.nextID++);
    li.innerHTML = content.gsub(/\{ID\}/, id);
    ol.appendChild(li);

    Events.autocompleteTagField(id);
    li.down("input").focus();

    if(item) {
      li.down("input.number").setValue(Money.formatValue(item.amount));
      li.down("input.tag").setValue(item.name);
    }
  },

  autocompleteTagField: function(id, options) {
    options = options || {};
    options.frequency = options.frequency || 0.2;
    options.onHide = options.onHide ||
      function(element, update) {
        new Effect.Fade(update,{
          duration:0.15,
          afterFinish:function() { update.innerHTML = ""; }
        })
      }

    new Autocompleter.Local(id, id + "_select", Events.tags, options);
  },

  autocompleteActorField: function(options) {
    options = options || {};
    options.frequency = options.frequency || 0.2;
    options.onHide = options.onHide ||
      function(element, update) {
        new Effect.Fade(update,{
          duration:0.15,
          afterFinish:function() { update.innerHTML = ""; }
        })
      }

    new Autocompleter.Local('event_actor_name', "event_actor_name_select",
      Events.actors, options);

    var element = $('event_actor_name');

    element.observe('keyup', function() {
      Events.recalledEvents = null;
      if(element.present()) {
        $('recall_event').show();
      } else {
        $('recall_event').hide();
      }
    });
  },

  removeTaggedItem: function(li) {
    li.remove();
  },

  updateUnassigned: function() {
    $('success_notice').hide();
    Events.updateUnassignedFor('payment_source');
    Events.updateUnassignedFor('credit_options');
    Events.updateUnassignedFor('deposit');
    Events.updateUnassignedFor('transfer_from');
    Events.updateUnassignedFor('transfer_to');
  },

  computeTotalForLineItems: function(section) {
    var total = 0;

    var line_items = $(section + ".line_items");
    line_items.select("input[type=text]").each(function(field) {
      total += Money.parse(field);
    });

    return total;
  },

  computeUnassignedFor: function(section) {
    var total = Money.parse('expense_total');
    var unassigned = total - Events.computeTotalForLineItems(section);
    return { 'total': total, 'unassigned': unassigned };
  },

  updateUnassignedFor: function(section) {
    if(!$(section)) return;

    var money = Events.computeUnassignedFor(section)

    if(money.unassigned > 0) {
      $(section + ".unassigned").innerHTML = "<strong>$" + Money.dollars(money.unassigned) + "</strong> of $" + Money.dollars(money.total) + " remains unallocated.";
    } else if(money.unassigned < 0) {
      $(section + ".unassigned").innerHTML = "You've overallocated <strong>$" + Money.dollars(money.unassigned) + "</strong>.";
    } else {
      $(section + ".unassigned").innerHTML = "";
    }
  },

  encodeXML: function(str) {
    return str.replace(/&/g, '&amp;' ).
               replace(/</g, '&lt;'  ).
               replace(/>/g, '&gt;'  ).
               replace(/'/g, '&apos;').
               replace(/"/g, '&quot;');
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
      xml += "<" + tag + ">" + Events.encodeXML(String(value)) + "</" + tag + ">";
    }

    return xml;
  },

  available: function(section) {
    return $(section) && $(section).visible();
  },

  sections: {
    payment_source : {expense:true},
    credit_options : {expense:true},
    deposit        : {expense:false},
    transfer_from  : {expense:true},
    transfer_to    : {expense:false},
    reallocate_from: {expense:false, reallocation: true},
    reallocate_to  : {expense:true, reallocation: true}
  },

  serialize: function(parent) {
    var request = {};

    request['event'] = {};
    request['event']['line_items'] = [];
    request['event']['tagged_items'] = [];
    request['authenticity_token'] = parent.querySelector("input[name=authenticity_token]").value;

    if(Events.available('general_information'))
      Events.serializeGeneralInformation(request);
    else {
      request['event']['occurred_on'] = Events.defaultDate;
      request['event']['actor_name'] = Events.defaultActor;
    }

    for(section in Events.sections) {
      if(Events.available(section))
        Events.serializeSection(request, section, Events.sections[section]);
    }

    Events.serializeTags(request);

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

    if($('expense_total')) {
      var total = Money.parse('expense_total');
      var expense = (options.expense ? -1 : 1) * total;
    }

    if(Events.sectionWantsCheckOptions(section) && $(section + '.check_options').visible()) {
      request['event']['check_number'] = $F($(section + '.check_options').down('input'));
    }

    single = $(section + '.single_bucket');
    if(single && single.visible()) {
      var bucket_id = $F($(section + '.single_bucket').down('select'));
      Events.addLineItem(request, account_id, bucket_id, expense, section);
      value = expense;
    } else {
      value = Events.addLineItems(request, account_id, section, options);
    }

    if(options.reallocation) {
      var bucket_id = $F($(section).down('p.primary').down('select'));
      Events.addLineItem(request, account_id, bucket_id, -value, 'primary');
    }

    if(section == 'credit_options') {
      Events.addLineItem(request, account_id, 'r:aside', total, 'aside');
    }
  },

  serializeTags: function(request) {
    if($('tags').visible()) {
      Events.serializeEventTags(request);
      if($('tag_items').visible())
        Events.serializeItemTags(request);
    }
  },

  serializeEventTags: function(request) {
    var tagList = $F('event_tags_list').strip();
    if(tagList.empty()) return;

    var total = Events.computeTotal();
    tagList.split(",").each(function(name) {
      Events.addTaggedItemRecord(request, total, "n:" + name.strip());
    });
  },

  serializeItemTags: function(request) {
    $('tagged_items').select('li').each(function(row) {
      var name = $F(row.down('input.tag')).strip();
      if(name.length > 0) {
        var amount = Money.parse(row.down('input.number'));
        Events.addTaggedItemRecord(request, amount, "n:" + name);
      }
    });
  },

  computeTotal: function() {
    if($('reallocate_to') && $('reallocate_to').visible()) {
      return Events.computeTotalForLineItems('reallocate_to');
    } else if($('reallocate_from') && $('reallocate_from').visible()) {
      return Events.computeTotalForLineItems('reallocate_from');
    } else {
      return Money.parse('expense_total');
    }
  },

  addTaggedItemRecord: function(request, amount, tag_id) {
    var item = { amount: amount, tag_id: tag_id };
    request['event']['tagged_items'].push(item);
  },

  addLineItem: function(request, account_id, bucket_id, amount, role) {
    var item = { account_id: account_id, bucket_id: bucket_id, amount: amount, role: role };
    request['event']['line_items'].push(item);
  },

  addLineItems: function(request, account_id, section, options) {
    options = options || {};
    value = 0;

    $(section + '.line_items').select('li').each(function(row) {
      bucket_id = $F(row.down('select'));
      field = row.down('input[type=text]');
      if(field.present()) {
        amount = (options.expense ? -1 : 1) * Money.parse(field);
        value += amount;
        Events.addLineItem(request, account_id, bucket_id, amount, section);
      }
    });

    return value;
  },

  submit: function(form) {
    try {
      // FIXME: validations!

      var options = {};
      var action = form.readAttribute('action');

      options.method = "post";
      options.contentType = "application/json";
      options.postBody = Object.toJSON(Events.serialize(form));

      return new Ajax.Request(action, options);
    } catch(e) {
      alert(e);
    }
  },

  highlightLink: function(id) {
    $('links').select('a').each(function(link) {
      if(link.id == id) {
        link.addClassName('highlight');
      } else {
        link.removeClassName('highlight');
      }
    })
  },

  revealMemo: function() {
    $('memo_link').hide();
    $('memo').show();
    $('memo').down('textarea').focus();
  },

  revealBasicForm: function() {
    $('new_event').show();
    $('success_notice').hide();
    $$('.expense_label').invoke('hide');
    $$('.deposit_label').invoke('hide');
    $$('.transfer_label').invoke('hide');
    $('general_information').show();
    $('payment_source').hide();
    $('credit_options').hide();
    $('deposit').hide();
    $('transfer_from').hide();
    $('transfer_to').hide();
    $('reallocate_from').hide();
    $('reallocate_to').hide();
  },

  revealExpenseForm: function() {
    Events.highlightLink('expense_link');
    Events.revealBasicForm();
    $$('.expense_label').invoke('show');
    $('payment_source').show();
  },

  revealDepositForm: function() {
    Events.highlightLink('deposit_link');
    Events.revealBasicForm();
    $$('.deposit_label').invoke('show');
    $('deposit').show();
  },

  revealTransferForm: function() {
    Events.highlightLink('transfer_link');
    Events.revealBasicForm();
    $$('.transfer_label').invoke('show');
    $('transfer_from').show();
    $('transfer_to').show();
  },

  revealReallocationForm: function(direction, account_id, bucket_id) {
    Events.revealBasicForm();
    $('general_information').hide();
    var section = 'reallocate_' + direction;
    $('account_for_' + section).value = account_id;
    $(section + ".line_items").innerHTML = "";
    $(section).show();
    Events.updateBucketsFor(section);
    Events.selectBucket($(section).down('select'), bucket_id);
    Events.addLineItemTo(section, true);
  },

  resetReallocationForm: function(direction) {
    var section = 'reallocate_' + direction;
    if($(section).visible()) {
      $(section + ".line_items").innerHTML = "";
      Events.addLineItemTo(section, true);
    }
  },

  revealTags: function() {
    $('tags_collapsed').hide();
    $('tags').show();
    $('tags').down("input").focus();
  },

  revealPartialTags: function(bare) {
    if(!bare) {
      Events.addTaggedItem();
      Events.addTaggedItem();
    }

    $('tag_items_collapsed').hide();
    $('tag_items').show();

    if(!bare) {
      $('tag_items').down('input').focus();
    }
  },

  reset: function() {
    $('event_form').reset();

    ['credit_options', 'payment_source', 'deposit', 'transfer_from', 'transfer_to'].each(
      function(section) {
        Events.handleAccountChange($('account_for_' + section), section);
      });

    ['from', 'to'].each(function(direction) {
      Events.resetReallocationForm(direction);
    });

    if($('memo')) {
      $('memo').hide();
      $('memo_link').show();
    }

    $('tag_items').hide();
    $('tag_items_collapsed').show();
    $('tagged_items').innerHTML = "";
    $('tags').hide();
    $('tags_collapsed').show();

    $('recall_event').hide();
  },

  cancel: function() {
    if(Events.return_to) {
      Events.returnToCaller();
    } else {
      Events.highlightLink("");
      Events.reset();
      $('new_event').hide();
    }
  },

  expand: function(id) {
    if($('zoomed_event_' + id)) return false;
    $('event_' + id).addClassName('zooming');
  },

  expanded: function(id) {
    $('event_' + id).removeClassName('zooming');
    $('event_' + id).addClassName('zoomed');
  },

  collapse: function(id) {
    $('event_' + id).removeClassName('zoomed');
    $('zoomed_event_' + id).remove();
  },

  onMouseOver: function(id) {
    $('event_' + id).addClassName("hover");
    var nubbin = $('nubbin_event_' + id);
    var offset = nubbin.up("tr").cumulativeOffset();

    nubbin.show();
    nubbin.style.left = (offset.left - nubbin.getWidth()) + "px";
  },

  onMouseOut: function(id) {
    $('event_' + id).removeClassName("hover");
    $('nubbin_event_' + id).hide();
  },

  deleteEvent: function(url, token) {
    if(confirm("Do you wish to delete this transaction?")) {
      parameters = 'authenticity_token=' + encodeURIComponent(token) + '&' +
                   'from=' + encodeURIComponent(Events.source);

      new Ajax.Request(url, {
        asynchronous:true,
        evalScripts:true,
        method:'delete',
        parameters:parameters
      });
    }
  },

  edit: function(url) {
    var return_to = window.location.pathname;
    window.location = url + "?return_to=" + encodeURIComponent(return_to);
  },

  destroy: function(id) {
    var table = $('event_' + id).up('table');
    $('event_' + id).remove();
    if($('zoomed_event_' + id)) $('zoomed_event_' + id).remove();
    var i = 1;
    table.select('tr').each(function(row) {
      if(i > 2) { // skip the balance and spacer rows
        row.removeClassName('odd').removeClassName('even');
        if(i % 2 == 0)
          row.addClassName('even');
        else
          row.addClassName('odd');
      }
      i++;
    })
  },

  returnToCaller: function() {
    window.location.href = Events.return_to;
  },

  recallEvent: function(url) {
    if(!Events.recalledEvents) {
      Events.loadRecalledEvents(url);
      return;
    }

    if(Events.recalledEvents.length == 0) {
      alert("No transactions matched the criteria you specified.");
      return;
    }

    Events.currentEvent = (Events.currentEvent + 1) % Events.recalledEvents.length;
    var event = Events.recalledEvents[Events.currentEvent].event;

    Events.rehydrate(event);
  },

  loadRecalledEvents: function(url) {
    parameters = 'page=0&size=10&actor=' + encodeURIComponent($F('event_actor_name'));
    new Ajax.Request(url, {
      asynchronous:true,
      evalScripts:true,
      method:'get',
      parameters:parameters
    });
  },

  doneLoadingRecalledEvents: function(events) {
    Events.recalledEvents = events;
    Events.currentEvent = -1;
    Events.recallEvent();
  },

  rehydrate: function(event) {
    var saved_date = $F('event_occurred_on');
    var saved_actor = $F('event_actor_name');

    Events.reset();

    $('event_occurred_on').value = saved_date;
    $('event_actor_name').value = saved_actor;
    $('expense_total').value = Money.formatValue(event.value);
    $('event_memo').value = event.memo;
    if($('event_memo').present()) Events.revealMemo();

    $('recall_event').show();

    switch(event.role) {
      case "expense": 
        Events.rehydrateExpenseEvent(event);
        break;
      case "deposit":
        Events.rehydrateDepositEvent(event);
        break;
      case "transfer":
        Events.rehydrateTransferEvent(event);
        break;
      case "reallocation":
        alert("Not yet implemented: can't rehydrate bucket reallocations");
        return;
      default:
        alert("Can't rehydrate '" + event.role + "' events");
        return;
    }

    Events.rehydrateTagsForEvent(event);
  },

  rehydrateSection: function(section, event) {
    var items = event.line_items.select(function(item) { return item.role == section; });
    if(items.length == 0) return;

    $(section).show();

    var account = Events.accounts[items[0].account_id];
    $('account_for_' + section).setValue(account.id);
    if(account.role == "checking" && Events.sectionWantsCheckOptions(section)) {
      $(section + '.check_options').show();
      $('event_check_number').setValue(event.check_number);
    }

    Events.updateBucketsFor(section);

    if(items.length == 1) {
      var select = $(section + '.single_bucket').down('select');
      Events.selectBucket(select, items[0].bucket_id);
    } else {
      $(section + '.multiple_buckets').show();
      $(section + '.single_bucket').hide();

      items.each(function(item) {
        Events.addLineItemTo(section, item);
      });
    }
  },

  rehydrateExpenseEvent: function(event) {
    Events.revealExpenseForm();
    Events.rehydrateSection('payment_source', event);
    Events.rehydrateSection('credit_options', event);
  },

  rehydrateDepositEvent: function(event) {
    Events.revealDepositForm();
    Events.rehydrateSection('deposit', event);
  },

  rehydrateTransferEvent: function(event) {
    Events.revealTransferForm();
    Events.rehydrateSection('transfer_from', event);
    Events.rehydrateSection('transfer_to', event);
  },

  rehydrateTagsForEvent: function(event) {
    var whole_tags = $A(), partial_tags = $A();

    event.tagged_items.each(function(item) {
      if(item.amount < event.value) {
        partial_tags.push(item);
      } else {
        whole_tags.push(item);
      }
    });

    if(whole_tags.length > 0 || partial_tags.length > 0) {
      Events.revealTags();
      if(whole_tags.length > 0) {
        var tags = whole_tags.map(function(item) { return item.name }).join(", ")
        $('tags').down('input').setValue(tags);
      }

      if(partial_tags.length > 0) {
        Events.revealPartialTags(true);
        partial_tags.each(function(item) {
          Events.addTaggedItem(item);
        });
      }
    }
  }
}

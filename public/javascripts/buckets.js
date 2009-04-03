var Buckets = {
  onMouseOver: function(id) {
    var nubbin = $('nubbin_bucket_' + id);
    var offset = nubbin.up("tr").cumulativeOffset();

    nubbin.show();
    nubbin.style.left = (offset.left - nubbin.getWidth()) + "px";
  },

  onMouseOut: function(id) {
    $('nubbin_bucket_' + id).hide();
  },

  configureEvent: function() {
    Events.defaultDate = new Date().toFormattedString();
    Events.defaultActor = "Bucket reallocation";
  },

  transferTo: function(account_id, bucket_id) {
    Buckets.configureEvent();
    Events.revealReallocationForm('to', account_id, bucket_id);
  },

  transferFrom: function(account_id, bucket_id) {
    Buckets.configureEvent();
    Events.revealReallocationForm('from', account_id, bucket_id);
  },

  view: function() {
    if($$('tr.bucket').any()) {
      return 'index';
    } else {
      return 'perma';
    }
  },

  rename: function(url, name, token) {
    new_name = prompt("Enter the name for this bucket:", name);
    if(new_name && new_name != name) {
      params = encodeURIComponent("bucket[name]") + "=" + encodeURIComponent(new_name) +
        "&authenticity_token=" + encodeURIComponent(token) + "&view=" + Buckets.view();

      new Ajax.Request(url, {
        asynchronous:true,
        evalScripts:true,
        method:'put',
        parameters:params
      });
    }
  },

  deleteBucket: function() {
    $('data').hide();
    $('delete_form').show();
  },

  confirmDelete: function() {
    return confirm("Are you sure you want to delete this bucket?");
  },

  cancelDelete: function() {
    $('delete_form').hide();
    $('data').show();
  }
}

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
  }
}

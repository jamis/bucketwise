var Filters = {
  display: function() {
    var form = $('filter_form');
    var nub = $('filter_nubbin');

    //form.style.right = (nub.offsetLeft + nub.getWidth()) + "px";
    form.show();
    form.style.left = (nub.offsetLeft + nub.getWidth() - form.getWidth()) + "px";
  },

  hide: function() {
    $('filter_form').hide();
  }
}

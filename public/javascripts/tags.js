var Tags = {
  rename: function(url, name, token) {
    new_name = prompt("Enter the name for this tag:", name);
    if(new_name && new_name != name) {
      params = encodeURIComponent("tag[name]") + "=" + encodeURIComponent(new_name) +
        "&authenticity_token=" + encodeURIComponent(token);

      new Ajax.Request(url, {
        asynchronous:true,
        evalScripts:true,
        method:'put',
        parameters:params
      });
    }
  }
}

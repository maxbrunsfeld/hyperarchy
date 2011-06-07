//= require jquery
//= require jquery_ujs
//= require monarch
//= require monarch/add_to_global_namespace
//= require jquery-ui/jquery.ui.core
//= require jquery-ui/jquery.ui.position
//= require jquery-ui/jquery.ui.widget
//= require jquery-ui/jquery.ui.mouse
//= require jquery-ui/jquery.ui.draggable
//= require jquery-ui/jquery.ui.droppable
//= require jquery-ui/jquery.ui.sortable
//= require jquery-ui/jquery.ui.autocomplete
//= require jquery-ui/jquery.effects.core
//= require jquery-ui/jquery.effects.highlight
//= require jquery.elastic.source
//= require jquery.holdplace
//= require jquery.phpdate
//= require jquery.caret
//= require jquery.tooltip.v.1.1
//= require jquery.hotkeys
//= require socket.io
//= require models
//= require views
//= require routes

Server.sandboxUrl = "/sandbox";
//window.debugEvents = true;

$.ajaxSetup({
  beforeSend: function(xhr) {
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
  }
});

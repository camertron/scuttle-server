$(document).ready(function() {
  var editor = ace.edit($(".editor").get(0));
  editor.getSession().setMode("ace/mode/sql");
  editor.setTheme("ace/theme/ambiance");
  editor.setShowPrintMargin(false);
  editor.renderer.setScrollMargin(7, 7, 7, 0);
  editor.session.setUseWrapMode(true);
  editor.setFontSize(14);

  if (editor.getValue() == "") {
    editor.setValue("SELECT COUNT(*)\nFROM posts\nWHERE posts.author = 'Mark Twain'\nORDER BY created_at DESC");
    editor.getSelection().clearSelection();
  }

  var update = function() {
    var jqxhr = $.get("convert.json", {sql: editor.getValue()}).done(function(data) {
      if (data.arel) {
        $(".arel").html(data.arel.replace("\n", "<br/>").replace(" ", "&nbsp;"));
      }
    }).fail(function() {
      // something should go here
    })
  };

  editor.addEventListener("change", function() {
    update();
  });

  update();
});
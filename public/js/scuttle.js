$(document).ready(function() {
  var timeout_handle = null;
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

  var update_with_delay = function() {
    if (timeout_handle != null) {
      window.clearTimeout(timeout_handle);
    }

    timeout_handle = window.setTimeout(update, 2000);
  };

  editor.addEventListener("change", function() {
    update_with_delay();
  });

  update();

  var beautify_sql = function(text) {
    var regex = /(SELECT|FROM|WHERE|GROUP BY|ORDER BY|RIGHT JOIN|LEFT JOIN|INNER JOIN|OUTER JOIN|JOIN)/g
    return text.replace(/\n/g, "").replace(regex, function(match) {
      return "\n" + match;
    }).substring(1);
  };

  $(".btn-beautify").click(function() {
    editor.setValue(beautify_sql(editor.getValue()));
  });
});

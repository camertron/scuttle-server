document.addEventListener("DOMContentLoaded", function(_event) {
  var timeoutHandle = null;
  var editor = ace.edit(document.querySelector(".editor"));
  var chkUseArelHelpers = document.querySelector("#chk-use-arel-helpers");
  var chkSimplifyArelNodes = document.querySelector("#chk-simplify-arel-nodes");
  var selRailsVersion = document.querySelector("#sel-rails-version");

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
    var body = new FormData();
    body.append("conversion[sql]", editor.getValue());
    body.append("conversion[use_arel_helpers]", chkUseArelHelpers.checked);
    body.append("conversion[use_arel_nodes_prefix]", !chkSimplifyArelNodes.checked);
    body.append("conversion[use_rails_version]", selRailsVersion.value);

    hideErrorMessage('.conversion-error-message');

    fetch('convert.json', { method: 'POST', body }).then((response) => {
      return response.json();
    }).then((data) => {
      if (data.result == 'succeeded') {
        if (data.arel) {
          document.querySelector('.arel').innerHTML = data.arel.replace("\n", "<br/>").replace(" ", "&nbsp;")
        }
      } else {
        showErrorMessage('.conversion-error-message', data.message);
      }
    }).catch((error) => {
      showErrorMessage('.conversion-error-message', 'An internal error occurred.');
    });
  };

  var updateWithDelay = function() {
    if (timeoutHandle != null) {
      window.clearTimeout(timeoutHandle);
    }

    timeoutHandle = window.setTimeout(update, 2000);
  };

  editor.addEventListener('change', updateWithDelay)
  chkUseArelHelpers.onclick = update;
  chkSimplifyArelNodes.onclick = update;
  selRailsVersion.onchange = update;

  update();

  var beautifySql = function(text) {
    var regex = /(SELECT|FROM|WHERE|GROUP BY|ORDER BY|RIGHT JOIN|LEFT JOIN|INNER JOIN|OUTER JOIN|JOIN|UNION)/g
    return text.replace(/\n/g, "").replace(regex, function(match) {
      return "\n" + match;
    }).substring(1);
  };

  document.querySelector('.btn-beautify').onclick = function() {
    editor.setValue(beautifySql(editor.getValue()));
  };

  function showErrorMessage(selector, message) {
    var container = document.querySelector(selector);
    var messageEl = container.querySelector('span');
    messageEl.text = message;
    container.style.display = "inline";
  }

  function hideErrorMessage(selector) {
    document.querySelector(selector).style.display = "none";
  }
});

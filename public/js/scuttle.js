$(document).ready(function() {
  var template = $($(".association-element").get(0)).clone();

  var timeoutHandle = null;
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
    var params = {
      sql: editor.getValue(),
      associations: JSON.stringify(getAssociations())
    };

    hideErrorMessage('.conversion-error-message');

    $.get("convert.json", params).done(function(data) {
      if (data.result == 'succeeded') {
        if (data.arel) {
          $(".arel").html(data.arel.replace("\n", "<br/>").replace(" ", "&nbsp;"));
        }
      } else {
        showErrorMessage('.conversion-error-message', data.message);
      }
    }).fail(function() {
      showErrorMessage('.conversion-error-message', 'An internal error occurred.');
    })
  };

  var updateWithDelay = function() {
    if (timeoutHandle != null) {
      window.clearTimeout(timeoutHandle);
    }

    timeoutHandle = window.setTimeout(update, 2000);
  };

  editor.addEventListener("change", function() {
    updateWithDelay();
  });

  update();

  var beautifySql = function(text) {
    var regex = /(SELECT|FROM|WHERE|GROUP BY|ORDER BY|RIGHT JOIN|LEFT JOIN|INNER JOIN|OUTER JOIN|JOIN)/g
    return text.replace(/\n/g, "").replace(regex, function(match) {
      return "\n" + match;
    }).substring(1);
  };

  $(".btn-beautify").click(function() {
    editor.setValue(beautifySql(editor.getValue()));
  });

  $(".btn-add-association").click(function() {
    addAssociation("", "", "", "", "");
  });

  function addAssociation(first, second, type, foreign_key, assoc_name) {
    var newForm = template.clone();
    fillAssociation(newForm, first, second, type, foreign_key, assoc_name);
    hookUpAssociation(newForm);
    $(".form-associations").append(newForm);
  }

  function hookUpAssociation(element) {
    $(".btn-remove", element).click(function() {
      $(this).parent().parent().remove();
    });
  }

  function fillAssociation(element, first, second, type, foreign_key, assoc_name) {
    $(".association-first", element).val(first);
    $(".association-second", element).val(second);
    $(".association-type", element).val(type);
    $(".association-foreign-key", element).val(foreign_key);
    $(".association-name", element).val(assoc_name);
  }

  // hook up events for the initial association form
  hookUpAssociation($($(".association-element").get(0)));

  function clearAll() {
    $(".association-element").remove();
  }

  function getAssociations() {
    var associations = [];

    $(".association-element").each(function(index, item) {
      associations.push({
        first: $(".association-first", item).val(),
        second: $(".association-second", item).val(),
        type: $(".association-type", item).val(),
        foreign_key: $(".association-foreign-key", item).val(),
        association_name: $(".association-name", item).val()
      });
    });

    return associations;
  }

  function showErrorMessage(selector, message) {
    var element = $(selector);
    $('span', element).text(message);
    element.show();
  }

  function hideErrorMessage(selector) {
    $(selector).hide();
  }

  $(".btn-github-import").click(function(e) {
    if (confirm("Importing from github will clear all current associations, is that ok?")) {
      hideErrorMessage('.import-error-message');
      var spinner = $(".import-spinner");
      spinner.show();

      $.getJSON("github_import.json", {repo: $(".form-github .github-repo").val()}).done(function(data) {
        if (data.result == 'succeeded') {
          clearAll();

          for (var i = 0; i < data.associations.length; i ++) {
            addAssociation(
              data.associations[i].first,
              data.associations[i].second,
              data.associations[i].type,
              data.associations[i].foreign_key,
              data.associations[i].association_name
            );
          }

          $(".form-github .github-repo").val("");
        } else {
          showErrorMessage('.import-error-message', data.message);
        }
      }).fail(function() {
        showErrorMessage('.import-error-message', 'An internal error occurred.');
      }).complete(function() {
        spinner.hide();
      });
    }

    e.preventDefault();
  });

  $(".btn-clear-all").click(function() {
    if (confirm("Are you sure you want to remove all associations?")) {
      clearAll();
    }
  });
});

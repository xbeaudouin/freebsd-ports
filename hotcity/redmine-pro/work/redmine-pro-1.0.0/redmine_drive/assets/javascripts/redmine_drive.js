/* =========================================== */
/*                 Sidebar menu                */
/* =========================================== */
function initializeSidebarMenu() {
  $('#drive-entries').on('change', 'input[type=checkbox].toggle-selection', toggleFilesSelection);

  $('#drive-entries').on('change', '.files.list input[name=ids\\[\\]]', function (event) {
    var checked = $(event.target).prop('checked');
    $(event.target)
      .prop('checked', checked)
      .parents('.hascontextmenu')
      .toggleClass('context-menu-selection', checked);

    resetSidebarMenu();
  });

  $(document).click(function (event) {
    if ($(event.target).attr('type') !== 'checkbox') {
      resetSidebarMenu()
    }
  });

  $(document).contextmenu(resetSidebarMenu);
};

function toggleFilesSelection(event) {
  var checked = $(this).prop('checked');
  var boxes = $(this).parents('table').find('input[name=ids\\[\\]]');
  boxes.prop('checked', checked).parents('.hascontextmenu').toggleClass('context-menu-selection', checked);
  resetSidebarMenu();
};

function resetSidebarMenu() {
  var $checkedItems = $('.files.list input[name=ids\\[\\]]:checked');
  var $sidebarMenu = $('#files-sidebar-menu');

  if ($checkedItems.size() === 0) {
    $sidebarMenu.empty();
    return;
  }

  var selectedIds = $checkedItems.map(function () { return this.value }).get();

  $.ajax({
    url: $('#drive-entries form').data('cm-url'),
    data: { ids: selectedIds, current_folder_id: $('#current_folder_id').val() },
    success: function(data, textStatus, jqXHR) { $sidebarMenu.html(data) }
  });
};

/* =========================================== */
/*                  Files tree                 */
/* =========================================== */
function getChildren(target, url) {
  $.ajax({
    url: url,
    type: 'GET',
    success: function (data) {
      $(data).insertAfter(target);
    }
  })
};

function toggleFolder(element, url) {
  var $folder = $(element).parents('tr.folder').first();

  if ($folder.next('tr[data-parent-id=' + $folder.data('id') + ']').size()) {
    if ($folder.hasClass('open')) {
      collapseFolder($folder)
    } else {
      expandFolder($folder)
    }
  } else {
    expandFolder($folder);
    getChildren($folder, url);
  }
};

function collapseFolder($folder) {
  $folder.removeClass('open');
  $folder.find('.expander').switchClass('icon-expended', 'icon-collapsed');
  var childrenSelector = 'tr[data-level]';
  var n = $folder.next(childrenSelector);
  while (n.length && n.data('level') > $folder.data('level')) {
    if (n.hasClass('open')) {
      n.removeClass('open')
      n.find('.expander').switchClass('icon-expended', 'icon-collapsed');
    }
    n.hide();
    n = n.next(childrenSelector);
  }
};

function expandFolder($folder) {
  $folder.addClass('open');
  $folder.find('.expander').switchClass('icon-collapsed', 'icon-expended');
  $folder.parents('table').find('tr[data-parent-id=' + $folder.data('id') + ']').show();
};

/* =========================================== */
/*             Files drag and drop             */
/* =========================================== */

function initializeFileDrop(target, newFilesPath) {
  if (window.File && window.FileList && window.ProgressEvent && window.FormData) {

    $.event.fixHooks.drop = { props: [ 'dataTransfer' ] };

    $(target).on({
      dragover: dragOverHandler,
      dragleave: dragOutHandler,
      drop: function (e) {
        $(this).removeClass('fileover');
        blockEventPropagation(e);
        filesDropEventHandler(e, newFilesPath);
      }
    });
  }
};

function filesDropEventHandler(event, newFilesPath) {
  if ($.inArray('Files', event.dataTransfer.types) > -1) {
    var files = event.dataTransfer.files;
    $.get(newFilesPath, function () {
      uploadAndAttachFiles(files, $('#new-files-form  input:file.filedrop'))
    });
  }
};

/* =========================================== */
/*                 Quick search                */
/* =========================================== */

(function ($) {
  $.fn.observe_field = function (frequency, callback) {
    frequency = frequency * 100; // Translate to milliseconds

    return this.each(function () {
      var $this = $(this);
      var prev = $this.val();

      var check = function () {
        if (removed()) { // If removed clear the interval and don't fire the callback
          if (ti) { clearInterval(ti) }
          return;
        }

        var val = $this.val();
        if (prev != val) {
          prev = val;
          $this.map(callback); // Invokes the callback on $this
        }
      };

      var removed = function () {
        return $this.closest('html').length == 0
      };

      var reset = function () {
        if (ti) {
          clearInterval(ti);
          ti = setInterval(check, frequency);
        }
      };

      check();
      var ti = setInterval(check, frequency); // Invoke check periodically

      // Reset counter after user interaction
      $this.bind('keyup click mousemove', reset); // mousemove is for selects
    });
  };
})(jQuery);

function initializeQuickSearch() {
  $('#search').observe_field(2, function() {
    var $form = $('#query_form');
    var url = $form.attr('action');

    $form.find('[name="c[]"] option').each(function(i, elem) {
      $(elem).prop('selected', true);
    });

    var formData = $form.serialize();

    $form.find('[name="c[]"] option').each(function(i, elem) {
      $(elem).prop('selected', false);
    });

    $.get(url, formData, function(data) {
      $('#drive-entries').html(data);
    });
  });
};

/* =========================================== */
/*                 Files Dialog                */
/* =========================================== */

function selectFilesDialog(newFilesPath) {
  $.get(newFilesPath, function () {
    $('#new-files-form input[type="file"]').click();
  });
};

/* =========================================== */
/*              Issue shared files             */
/* =========================================== */

function removeSharedFileField(target) {
  $(target).siblings('.destroy-value').val('1');
  $(target).parents('.shared-file-field').hide();
};

function observeFilesSearchField(fieldId, targetId, url) {
  $('#'+fieldId).each(function() {
    var $this = $(this);
    $this.addClass('autocomplete');
    $this.attr('data-value-was', $this.val());
    var check = function() {
      var val = $this.val();
      if ((val.length === 0 || val.length > 1) && $this.attr('data-value-was') != val){
        $this.attr('data-value-was', val);
        $.ajax({
          url: url,
          type: 'get',
          data: {q: $this.val()},
          success: function(data){ if(targetId) $('#'+targetId).html(data); },
          beforeSend: function(){ $this.addClass('ajax-loading'); },
          complete: function(){ $this.removeClass('ajax-loading'); }
        });
      }
    };
    var reset = function() {
      if (timer) {
        clearInterval(timer);
        timer = setInterval(check, 300);
      }
    };
    var timer = setInterval(check, 300);
    $this.bind('keyup click mousemove', reset);
  });
};

/* =========================================== */
/*                    Other                    */
/* =========================================== */

function copyTokenToClipboard(id) {
  var copyText = document.getElementById(id);
  copyText.select();
  document.execCommand('copy');
};

function showFolderContent(url) {
  $.get(url, function(data) {
    $('#file-explorer').html(data);
  });
};

/*
This file is a part of Redmine Resources (redmine_resources) plugin,
resource allocation and management for Redmine

Copyright (C) 2011-2020 RedmineUP
http://www.redmineup.com/

This file is covering by RedmineUP Proprietary Use License as any images,
cascading stylesheets, manuals and JavaScript files in any extensions
produced and/or distributed by redmineup.com. These files are copyrighted by
redmineup.com (RedmineUP) and cannot be redistributed in any form
without prior consent from redmineup.com (RedmineUP)

*/
function addParamsToURL(url, data) {
  if (!$.isEmptyObject(data)) {
    url += (url.indexOf('?') >= 0 ? '&' : '?') + $.param(data);
  }

  return url;
};

function addEditableBarsOnClickListener() {
  $('.resource-planning-chart #gantt_area').on('click', '.booking-bar', function () {
    if ($(this).hasClass('no-click')) {
      $(this).removeClass('no-click')
    } else {
      var editUrl = this.getAttribute('edit_url');
      if (editUrl) {
        $.ajax(addParamsToURL(editUrl))
      }
    }
  });
};
function initializeDraggableBars(columnWidth) {
  var $resourceLines = $('.resource-planning-chart #gantt_area .resource-lines');

  $resourceLines.find('.booking-bar.editable').not('.ui-draggable').draggable({
    axis: 'x',
    grid: [columnWidth, 1],
    cursor: 'move',
    start: function(event, ui) {
      $(event.target).addClass('no-click');
      $resourceLines.addClass('is-active');
    },
    stop: function(event, ui) {
      $resourceLines.removeClass('is-active');

      var daysOffset = (ui.position.left - ui.originalPosition.left) / columnWidth;
      if (daysOffset !== 0) {
        $.ajax({
          type: 'POST',
          url: addParamsToURL(this.getAttribute('update_url'), { start_date_offset: daysOffset, end_date_offset: daysOffset })
        });
      }
    }
  });
};

function initializeResizableBars(columnWidth) {
  var $resourceLines = $('.resource-planning-chart #gantt_area .resource-lines');

  $resourceLines.find('.booking-bar.editable').not('.ui-resizable').resizable({
    handles: 'e, w',
    grid: [columnWidth, 1],
    cursor: 'ew-resize',
    start: function(event, ui) {
      $(event.target).addClass('no-click');
      $resourceLines.addClass('is-active');
      $resourceLines.css({ cursor: 'ew-resize' });
    },
    stop: function(event, ui) {
      $resourceLines.removeClass('is-active');
      $resourceLines.css({ cursor: 'auto' });

      var $bar = $(this);

      // This hack is needed for JQuery UI version 1.11.0
      // There are also other problems for versions 1.11.1 and 1.11.2
      if (ui.size.width == columnWidth) {
        $bar.css({ left: ui.position.left + 2, width: columnWidth - 2 });
      }

      if (Math.abs($bar.width() - ui.originalSize.width) < columnWidth) { return }

      var positionOffset = $bar.position().left - ui.originalPosition.left;
      var queryParams = {};
      if (positionOffset !== 0) {
        queryParams['start_date_offset'] = positionOffset / columnWidth
      } else {
        queryParams['end_date_offset'] = ($bar.width() - ui.originalSize.width) / columnWidth;
      }

      $.ajax({
        type: 'POST',
        url: addParamsToURL(this.getAttribute('update_url'), queryParams)
      });
    }
  });
};

function initializeAddBookingButtons(columnWidth) {
  var $ganttArea = $('.resource-planning-chart #gantt_area');
  var $resourceLines = $ganttArea.find('.resource-lines');

  $ganttArea.on('mousemove', '.issue-line', function (event) {
    var $buttonAddBooking = $(this).children('.button-add-booking');
    if (!$buttonAddBooking.hasClass('is-active')) {
      var cursorLeft = event.pageX - $ganttArea.position().left + $ganttArea.scrollLeft();
      var columnLeft = Math.floor(cursorLeft / columnWidth) * columnWidth;
      $buttonAddBooking.css({left: columnLeft, width: columnWidth - 2});
    }
  });

  $ganttArea.on('mousedown', '.button-add-booking', function (event) {
    if (event.which == 1) { // Left button
      $(event.target).parent('.button-add-booking').addClass('is-active');
      $resourceLines.addClass('is-active');
      $resourceLines.css({ cursor: 'ew-resize' });
    }
  });

  $ganttArea.on('click', '.button-add-booking', function (event) {
    $resourceLines.removeClass('is-active');
    $resourceLines.css({ cursor: 'auto' });

    var $this = $(this);
    $this.removeClass('is-active');

    var daysOffset = this.offsetLeft / columnWidth;
    $.ajax(addParamsToURL($this.parent().attr('data-new-url'), { start_date_offset: daysOffset, end_date_offset: daysOffset }))
  });

  initializeResizableAddBookingButtons(columnWidth);
};

function initializeResizableAddBookingButtons(columnWidth) {
  var $resourceLines = $('.resource-planning-chart #gantt_area .resource-lines');

  $('.issue-line .button-add-booking').not('.ui-resizable').resizable ({
    handles: 'e',
    grid: [columnWidth, 1],
    cursor: 'ew-resize',
    stop: function(event, ui) {
      $resourceLines.removeClass('is-active');
      $resourceLines.css({ cursor: 'auto' });

      var queryParams = {
        start_date_offset: ui.position.left / columnWidth,
        end_date_offset: (ui.position.left + ui.size.width) / columnWidth
      }

      $.ajax({
        url: addParamsToURL($(this).parent('.issue-line').attr('data-new-url'), queryParams),
        success: function(data) {
          $(event.target).removeClass('is-active');
        }
      });
    }
  });
};

function initializeBarSplitLines(columnWidth) {
  var $ganttArea = $('.resource-planning-chart #gantt_area');
  $ganttArea.on('mousemove', '.booking-bar.editable', function(event) {
    var $splitLine = $(this).children('.split-line');
    var cursorLeft = event.pageX - $ganttArea.position().left - $(this).position().left + $ganttArea.scrollLeft();
    if (cursorLeft % columnWidth < columnWidth / 2) {
      $splitLine.css({ left: Math.floor(cursorLeft / columnWidth) * columnWidth - 2 });
    }
  });

  $ganttArea.on('click', '.booking-bar.editable .split-line', function(event) {
    event.stopPropagation();
    if (window.confirm('This action will create two assignments around the selected date. Proceed?')) {
      $.post(
        $(this).parent('.booking-bar.editable').attr('data-split-url'),
        { split_offset: ($(this).position().left + 2) / columnWidth }
      );
    }
  });
};

function initializeResizableSubjectsColumn() {
  $('td.gantt_subjects_column').resizable({
    alsoResize: '.gantt_subjects_container, .gantt_subjects_container>.gantt_hdr',
    minWidth: 100,
    handles: 'e',
  });

  if(isMobile()) {
    $('td.gantt_subjects_column').resizable('disable');
  } else{
    $('td.gantt_subjects_column').resizable('enable');
  };
};

function updateUserBlock(userId, subjects, lines) {
  var $userSubjectsBlock = $('.resource-planning-chart div.resource-subjects [group_id=' + userId + ']');
  if ($userSubjectsBlock.length === 1) {
    $userSubjectsBlock.replaceWith(subjects);
    $('.resource-planning-chart div.resource-lines [group_id=' + userId + ']').replaceWith(lines)
  } else {
    $('.resource-planning-chart .gantt_subjects_column .resource-subjects').append(subjects);
    $('.resource-planning-chart #gantt_area .resource-lines').append(lines);
  }
};

function renderFlashMessages(html) {
  var $content = $('#content');
  $content.children('[id^="flash_"]').remove();
  $content.prepend(html);
};

function updateResourceBookingFrom(url) {
  $.ajax({
    url: url,
    data: $('#resource-booking-form').serialize()
  });
};

function formatStateWithLineThrough(opt) {
  if (opt.line_through) {
    return $('<span class="crossed-out-option">' + opt.text + '</span>');
  } else {
    return $('<span>' + opt.text + '</span>');
  }
};

function toggleAllUserResourceBookingsGroups() {
  var $groups = $('.user-resource-bookings');
  if ($groups.first().hasClass('open')) {
    $groups.removeClass('open');
  } else {
    $groups.addClass('open');
  }
};

function toggleBlockGroup(groupName, value) {
  $('.' + groupName).hide();
  $('.' + groupName + '.' + value).show();
};

function toggleBookingRowGroup(el) {
  var tr = $(el).parents('tr').first();
  var n = tr.next();
  tr.toggleClass('open');
  $(el).toggleClass('icon-expended icon-collapsed');
  while (n.length && !n.hasClass('group')) {
    if (n.hasClass('booking-data')) {
      n.toggle();
    }
    n = n.next('tr');
  }
};

function toggleAllBookingRowGroups(el) {
  var tr = $(el).parents('tr').first();
  if (tr.hasClass('open')) {
    collapseAllBookingRowGroups(el);
  } else {
    expandAllRowGroups(el);
  }
};

function collapseAllBookingRowGroups(el) {
  var tbody = $(el).parents('tbody').first();
  tbody.children('tr').each(function(index) {
    if ($(this).hasClass('group')) {
      $(this).removeClass('open');
      $(this).find('.expander').switchClass('icon-expended', 'icon-collapsed');
    } else {
      if ($(this).hasClass('booking-data')) {
        $(this).hide();
      }
    }
  });
};

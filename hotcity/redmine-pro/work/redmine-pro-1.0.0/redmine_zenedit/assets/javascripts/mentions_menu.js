
function mentionsMenu(jsZenEdit, autoCompleteURL) {
  this.jsZenEdit = jsZenEdit;
  this.$textArea = jsZenEdit.$textArea;
  this.selectionStart = this.$textArea[0].selectionEnd;
  this.autoCompleteURL = autoCompleteURL;

  var caret = getCaretCoordinates(this.$textArea[0], this.$textArea[0].selectionEnd);
  this.left = this.$textArea.offset().left + caret.left;
  this.top = this.$textArea.offset().top + caret.top + caret.height - this.$textArea.scrollTop();

  this.addEventListeners();
  this.update();
}

mentionsMenu.prototype = {
  update: function () {
    var that = this;
    if (that.$textArea[0].selectionEnd < that.selectionStart) {
      that.destroy();
      return;
    }

    $.ajax({
      url: that.autoCompleteURL,
      type: 'get',
      data: { q: that.query() },
      success: function(data) {
        that.destroy();
        that.$menu = $("<ul style='position:absolute;'></ul>");

        if (data.length > 0) {
          that.addMenuItem(data[0], true);
          for (var i = 1; i < data.length; i++) {
            that.addMenuItem(data[i]);
          }
        }

        $("body").append(that.$menu);
        that.$menu.menu().css({ left: that.left, top: that.top });
      }
    });

    $('#ajax-indicator').hide();
  },

  destroy: function () {
    if (this.$menu) {
      this.$menu.remove();
      this.$menu = undefined;
    }
  },

  addMenuItem: function (item, selected) {
    var that = this;
    $menuItem = $(
      '<li class="zen_mention-menu-item">' +
      '<span>' + item['label'] + '</span>' +
      '<small class="menu-item-info">' + item['value'] + '</small></li>'
    );

    if (selected) { $menuItem.addClass('selected') }

    $menuItem.appendTo(that.$menu);
    $menuItem.mousedown(function () { that.chooseMenuItem($(this)) });
  },

  query: function () {
    return this.$textArea.val().substring(this.selectionStart, this.$textArea[0].selectionEnd);
  },

  selectNextMenuItem: function () {
    var $selectedMenuItem = this.$menu.find('.selected');
    var $nextMenuItem = $selectedMenuItem.next('li.zen_mention-menu-item');
    $selectedMenuItem.removeClass('selected');
    if ($nextMenuItem.size() > 0) {
      $nextMenuItem.addClass('selected')
    } else {
      this.$menu.find('li.zen_mention-menu-item').first().addClass('selected');
    }
  },

  selectPreviousMenuItem: function () {
    var $selectedMenuItem = this.$menu.find('.selected');
    var $previousMenuItem = $selectedMenuItem.prev('li.zen_mention-menu-item');
    $selectedMenuItem.removeClass('selected');
    if ($previousMenuItem.size() > 0) {
      $previousMenuItem.addClass('selected')
    } else {
      this.$menu.find('li.zen_mention-menu-item').last().addClass('selected');
    }
  },

  chooseCurrentMenuItem: function () {
    this.chooseMenuItem(this.$menu.find('.selected'));
    this.destroy();
  },

  chooseMenuItem: function ($menuItem) {
    this.$textArea[0].selectionStart = this.selectionStart;
    this.jsZenEdit.insertIntoTextarea($menuItem.find('small').text());
  },

  addEventListeners: function () {
    var that = this;

    $(document).on("mousedown", function () {
      that.destroy();
    });

    that.$textArea.on('keydown', function (event) {
      if (that.$menu) {
        if (event.which == 38 || event.keyCode == 38) { // Arrow up
          that.selectPreviousMenuItem();
          return false;
        } else if (event.which == 40 || event.keyCode == 40) { // Arrow down
          that.selectNextMenuItem();
          return false;
        } else if (event.which == 13 || event.keyCode == 13) { // Enter
          that.chooseCurrentMenuItem();
          return false;
        }
      }
    });
  }
};

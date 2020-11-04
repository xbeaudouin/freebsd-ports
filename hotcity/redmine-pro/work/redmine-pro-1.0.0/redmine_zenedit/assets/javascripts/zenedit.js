function jsZenEdit(textArea, options) {
  if (!document.createElement) { return; }

  if (!textArea) { return; }

  if ((typeof(document["selection"]) == "undefined")
  && (typeof(textArea["setSelectionRange"]) == "undefined")) {
    return;
  }

  this.options = options || {};
  this.title = this.options['title'] || 'Zen';
  this.$textArea = $(textArea);
  this.$textArea.attr('placeholder', this.options['placeholder']);

  var $jstEditor = this.$textArea.parent('.jstEditor');
  this.$jstEditor = $jstEditor;

  var $jstBlock = $jstEditor.parent();
  this.$toolBar = $jstBlock.find('.jstElements');

  var that = this;

  // Add the theme button
  var $themeButton = $('<button type="button" tabindex="200" class="jstb_zenedit theme"></button>');
  $themeButton.attr('title', this.title);
  $jstEditor.append($themeButton);
  $themeButton.on('click', function () {
    try {
      $jstEditor.toggleClass('dark-theme');
      that.$textArea.focus();
    } catch (e) {}
    return false;
  });

  this.addZenButton();

  // Add listener for "escape" key
  document.onkeydown = function (evt) {
    evt = evt || window.event;
    if (evt.keyCode == 27) {
      var $jstElements = $('.jstElements.zen').removeClass('zen');
      $jstElements.removeAttr("style");

      var $jstEditor = $('.jstEditor.zen');
      $jstEditor.removeClass('zen');

      var $textArea = $jstEditor.find('textarea');
      $textArea.removeAttr("style");
      $textArea.focus();

      $('html.zen').removeClass('zen');
      $('#zenPreview').remove();
    }
  };
  if (this.options['enableUserMentions'] && this.isIssueTextArea()) {
    this.enableUserMentions();
  }

  if (this.options['enableIssueMentions'] && this.isIssueTextArea()) {
    this.enableIssueMentions();
  }

  addSubmitAndPreviewButtons(this.$toolBar, this.$textArea, this.options['previewURL']);
}
function addSubmitAndPreviewButtons($toolBar, $textArea, previewURL) {
  $(function () {
    var zenElements = $('<span class="zenElements"></span>');
    zenElements.append('<span id="zen_space1" class="jstSpacer">&nbsp;</span>');
    zenElements.append('<button tabindex="200" class="jstb_zen_submit" title="Submit">Submit</button>');

    var zenPreviewBtn = $('<button type="button" tabindex="200" class="jstb_zen_preview" title="Preview">Preview</button>');
    zenElements.append(zenPreviewBtn);

    zenPreviewBtn.on('click ', function() {
      var $zenPreview = $('<div id="zenPreview" class="wiki"></div>');
      $textArea.after($zenPreview);
      $zenPreview.on('click', function() {
        $textArea.show();
        $toolBar.show();
        $zenPreview.remove();
      });

      submitZenPreview(previewURL, $textArea, $zenPreview);
      $textArea.hide();
      $toolBar.hide();
    });

    $toolBar.append(zenElements);
  });
};


function submitZenPreview(url, $textArea, $target) {
  var $form = $textArea.closest('form');
  if ($form.size() > 0) {
    var data = $form.serialize() + '&text=' + $textArea.val();
  } else {
    var data =  { text: $textArea.val() };
  }

  $.ajax({
    url: url,
    type: 'post',
    data: data,
    success: function(data) { $target.html(data); }
  });
};


jsZenEdit.prototype = {
  enableUserMentions: function() {
    this.addUserMentionsButton();
    this.addMentionsMenuListener('@', this.options['usersAutoCompleteURL']);
  },

  enableIssueMentions: function() {
    this.addMentionsMenuListener('#', this.options['issuesAutoCompleteURL']);
  },

  addUserMentionsButton: function() {
    this.$toolBar.append('<span id="zen_mention_space" class="jstSpacer">&nbsp;</span>');
    var $mentionBtn = $('<button type="button" tabindex="200" class="icon icon-user" title="Project members"><span>Project members</span></button>');
    this.$toolBar.append($mentionBtn);

    var that = this;
    $mentionBtn.on('click ', function () {
      var textArea = that.$textArea[0];
      var cursorPosition = textArea.selectionEnd;
      if (cursorPosition > 0 && textArea.value.substr(cursorPosition - 1, 1).match(/\S/)) {
        that.insertIntoTextarea(' @');
      } else {
        that.insertIntoTextarea('@');
      }

      that.showMentionsMenu(that.options['usersAutoCompleteURL']);
    });
  },

  addMentionsMenuListener: function(activationChar, autoCompleteURL) {
    var that = this;
    this.$textArea.on('input', function (e) {
      var char = that.$textArea.val()[that.$textArea[0].selectionEnd - 1];

      if (that.mentionsMenuIsActive()) {
        if (char === ' ') {
          that.mentionsMenu.destroy();
        } else {
          that.mentionsMenu.update();
        }
      } else if (that.canShowMentionsMenu(activationChar)) {
        that.showMentionsMenu(autoCompleteURL);
      }
    });
  },

  mentionsMenuIsActive: function() {
    return this.mentionsMenu && this.mentionsMenu.$menu
  },

  canShowMentionsMenu: function(activationChar) {
    var index = this.$textArea[0].selectionEnd - 1;
    var str = this.$textArea.val();
    return str[index] === activationChar && (index === 0 || str[index - 1] === ' ' || str[index - 1] === '\n')
  },

  showMentionsMenu: function(autoCompleteURL) {
    if (this.mentionsMenu) { this.mentionsMenu.destroy() }
    this.mentionsMenu = new mentionsMenu(this, autoCompleteURL);
  },

  isIssueTextArea: function() {
    var textAreaId = this.$textArea[0].id;
    return textAreaId === 'issue_description' || textAreaId === 'issue_notes'
  },

  addZenButton: function () {
    var that = this;

    that.$zenButton = $('<button type="button" tabindex="200" class="jstb_zenedit"></button>');
    that.$zenButton.attr('title', this.title);
    that.$jstEditor.append(that.$zenButton);

    that.$zenButton.on('click', function () {
      try {
        that.$jstEditor.toggleClass('zen');
        that.$toolBar.toggleClass('zen');
        that.$toolBar.removeAttr("style");
        that.$textArea.removeAttr("style");
        $('#zenPreview').remove();
        $('html').toggleClass('zen');
        that.$textArea.focus();
      } catch (e) {}
      return false;
    });

    // Toggle together with $textArea
    if ('MutationObserver' in window) {
      var observer = new MutationObserver(function(mutationList, observer) { that.visibilityByTextArea(that.$zenButton) });
      observer.observe(that.$textArea[0], { 'attributes': true, 'attributeFilter': ['class'] });
    } else {
      $(document).on('click', function (event) { that.visibilityByTextArea(that.$zenButton) });
      $(document).on('keydown', function (event) {
        if (event.which == 13 || event.keyCode == 13) { // Enter
          that.visibilityByTextArea(that.$zenButton)
        }
      });
    }
  },

  visibilityByTextArea: function($target) {
    $target.toggle(!this.$textArea.is(':hidden'))
  },

  insertIntoTextarea: function(text) {
    var textArea = this.$textArea[0];
    textArea.focus();

    if (typeof(document['selection']) != 'undefined') {
      document.selection.createRange().text = text;
      var range = textArea.createTextRange();
      range.collapse(false);
      range.select();
    } else if (typeof(textArea['setSelectionRange']) != 'undefined') {
      var start = textArea.selectionStart;
      var end = textArea.selectionEnd;
      var scrollPos = textArea.scrollTop;

      textArea.value = textArea.value.substring(0, start) + text + textArea.value.substring(end);
      textArea.setSelectionRange(start + text.length, start + text.length);
      textArea.scrollTop = scrollPos;
    }
  }
};

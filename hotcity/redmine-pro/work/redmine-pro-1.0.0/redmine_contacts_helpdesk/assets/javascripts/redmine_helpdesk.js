function togglePrivateTicketsOnChange() {
  var checked = $(this).is(':checked');
  $('.private_tikets').attr('disabled', !checked);
}

function togglePrivateTicketsInit() {
  $('.assign_contact_user').each(togglePrivateTicketsOnChange);
}

function toggleStatusesForAutoclose(node) {
  if ($(node).val() == ''){
    $('#statuses_autoclose').hide();
  } else {
    $('#statuses_autoclose').show();
  }
}

function ccEmailTagResult (opt) {
  if (opt.name){
    var formated_tag = $('<span>' + opt.avatar + '&nbsp;' + opt.text + '</span>');;
  } else {
    var formated_tag = opt.text;
  }
  return formated_tag
};

function ccEmailTagSelection (opt) {
  if (opt.name){
    var formated_tag = opt.name + ' <' + opt.email + '>';
  } else {
    var formated_tag = opt.text;
  }
  return formated_tag
};

function showConfiguredSend(id, focus, checked) {
  send_mail_input = $('#helpdesk_is_send_mail');
  send_mail_input.prop( "checked", checked );
  send_mail_input.checked = checked;
  toggleSendMail(send_mail_input);
}

$(document).ready(function(){
  $('#content').on('change', '.assign_contact_user', togglePrivateTicketsOnChange);
  togglePrivateTicketsInit();

  var ticket_data = $('#ticket_data');
  $('#history .contextual a[title="Quote"]').click(function(){
    if (ticket_data.length > 0) {
      var journal_id = this.href.match(/journal_id=(\d*)/)[1];
      $.ajax({
        method: 'GET',
        url: ticket_data.data("customerEmailUpdatePath"),
        dataType: 'script',
        data: { journal_id: journal_id }
      });
    }
  });
});

function addAttachment(filename, token, description, deleteURL) {
  var inputEl = $('.attachments_form input[type="file"]');
  var attachmentsFields = $(inputEl).closest('.attachments_form').find('.attachments_fields');

  var attachmentId = addFile.nextAttachmentId++;
  var fileSpan = $('<span>', { id: 'attachments_' + attachmentId });
  var param = $(inputEl).data('param');
  if (!param) { param = 'attachments' };

  fileSpan.append(
    $('<input>', { type: 'text', 'class': 'icon icon-attachment filename readonly', name: param +'[' + attachmentId + '][filename]', readonly: 'readonly' }).val(filename),
    $('<input>', { type: 'text', 'class': 'description', name: param + '[' + attachmentId + '][description]', maxlength: 255, placeholder: $(inputEl).data('description-placeholder') }).val(description),
    $('<input>', { type: 'hidden', 'class': 'token', name: param + '[' + attachmentId + '][token]'} ).val(token),
    $('<a>&nbsp</a>').attr({ href: deleteURL + '?attachment_id=' + attachmentId, 'class': 'icon-only icon-del remove-upload', 'data-remote': true, 'data-method': 'delete' })
  ).appendTo(attachmentsFields);

  if ($(inputEl).data('description') == 0) {
    fileSpan.find('input.description').remove();
  }
};

function addCannedResponseButton(data) {
  jsToolBar.prototype.elements.responses = {
    type: 'button',
    title: 'Canned responses',
    fn: {
      wiki: function() {
        var editor = this,
            $dropdown = $('<select class="canned-responses__menu" multiple="multiple"></select>');

        data.responses.forEach(function(response) {
          option = $('<option></option>');
          option.attr('value', response.id);
          option.text(response.name);
          option.appendTo($dropdown)
        })

        $('body').append($dropdown);
        $dropdown.select2();
        $dropdownContainer = $dropdown.data('select2').$container

        $dropdownContainer.position({
          my: 'left top',
          at: 'left bottom',
          of: this.toolNodes.responses
        });

        $dropdown.select2('open');
        $dropdown.on('select2:select', function(e){
          updateCannedResposeFrom(data.url, e.params.data.id)
          $dropdown.remove();
          $dropdownContainer.remove();
        });

        $(document).on('mousedown', function() {
          if ($dropdown.hasClass("select2-hidden-accessible")) { $dropdown.select2('destroy') };
          $dropdown.remove();
        });
      }
    }
  };
}

function showHelpdeskHistory(tabName, url) {
  showIssueHistory(tabName, url);
  tab_content = $('#tab-content-history');

  tab_content.find('.journal:not(.has-journal-message)').hide();
  tab_content.find('.journal.has-journal-message').show();
}

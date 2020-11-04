function addReportTemplatesCheckboxesListener() {
  $(document).ready(function() {
    $('#report_templates input[type=checkbox]').on('change', function () { extraLinksToggle() });
  });
};

function extraLinksToggle() {
  if ($('#report_templates input[type=checkbox]:checked').size() > 0) {
    $('form p.other-formats').show();
  } else {
    $('form p.other-formats').hide();
  }
};

function submitMessageFormPreview(url) {
  $.ajax({
    url: url,
    type: 'post',
    data: $('#message-form').serialize(),
    success: function(data){
      $('#preview').html(data);
    }
  });
};

function initActions() {
  $('#add_action_select').change(function() {
    addAction($(this).val(), '', []);
  });
  $('#actions-table td.field input[type=checkbox]').each(function() {
    toggleAction($(this).val());
  });
  $('#actions-table').on('click', 'td.field input[type=checkbox]', function() {
    toggleAction($(this).val());
  });
  $('#actions-table').on('click', '.toggle-multiselect', function() {
    toggleMultiSelect($(this).siblings('select'));
  });
  $('#actions-table').on('keypress', 'input[type=text]', function(e) {
    if (e.keyCode == 13) $(this).closest('form').submit();
  });
}

function addAction(field, operator, values) {
  var fieldId = field.replace('.', '_');
  var tr = $('#tr_action_'+fieldId);

  var actionOptions = availableActions[field];
  if (!actionOptions) return;

  if (actionOptions['remote'] && actionOptions['values'] == null) {
    $.getJSON(actionsUrl, {'name': field}).done(function(data) {
      actionOptions['values'] = data;
      addAction(field, operator, values) ;
    });
    return;
  }

  if (tr.length > 0) {
    tr.show();
  } else {
    buildMailRuleRow(field, operator, values,  $("#actions-table"));
  }
  $('#cb_action_'+fieldId).prop('checked', true);
  toggleAction(field);
  $('#add_action_select').val('').find('option').each(function() {
    if ($(this).attr('value') == field) {
      $(this).attr('disabled', true);
    }
  });
}

function toggleAction(field) {
  var fieldId = field.replace('.', '_');
  if ($('#cb_action_' + fieldId).is(':checked')) {
    toggleActionOperator(field);
  } else {
    enableActionValues(field, []);
  }
}

function enableActionValues(field, indexes) {
  var fieldId = field.replace('.', '_');
  $('#tr_action_'+fieldId+' td.values .value').each(function(index) {
    if ($.inArray(index, indexes) >= 0) {
      $(this).removeAttr('disabled');
      $(this).parents('span').first().show();
    } else {
      $(this).val('');
      $(this).attr('disabled', true);
      $(this).parents('span').first().hide();
    }

    if ($(this).hasClass('group')) {
      $(this).addClass('open');
    } else {
      $(this).show();
    }
  });
}


function buildMailRuleRow(field, operator, values, destination) {
  var fieldId = field.replace('.', '_');
  var actionOptions = availableActions[field];
  if (!actionOptions) return;
  var actionValues = actionOptions['values'];
  var i, select, operators;

  if (actionOptions['type'] == "date_with_labels") {
    operators = operatorByType[actionOptions['type']];
  }

  var filter_html = ''
  filter_html +='<td class="field"><input checked="checked" id="cb_action_'+fieldId+'" name="a[]" value="'+field+'" type="checkbox"><label for="cb_'+fieldId+'"> '+actionOptions['name']+'</label></td>'
  if (operators && operators.length > 0) {
    operators_html = '<td class="operator"><select id="operators_'+fieldId+'" name="op['+field+']" onChange="toggleActionOperator(\''+field+'\')">'
    for (i = 0; i < operators.length; i++) {
      var option = $('<option>').val(operators[i]).text(operatorLabels[operators[i]]);
      if (operators[i] == operator) { option.prop('selected', true); option.attr('selected', true); }
      operators_html += option[0].outerHTML;
    }
    operators_html += '</select></td>'
    filter_html += operators_html
  } else {
    filter_html += '<td></td>'
  }
  filter_html += '<td class="values"></td>'

  var tr = $('<tr class="action filter">').attr('id', 'tr_action_'+fieldId).html(filter_html);
  destination.append(tr);

  switch (actionOptions['type']) {
  case "list":
  case "list_optional":
  case "list_status":
  case "list_subprojects":
    tr.find('td.values').append('<span style="display:none;"><select class="value" id="values_'+fieldId+'_1" name="v['+field+'][]"></select>');
    select = tr.find('td.values select');
    if (values.length > 1) { select.attr('multiple', true); }
    for (i = 0; i < actionValues.length; i++) {
      var actionValue = actionValues[i];
      var option = $('<option>');
      if ($.isArray(actionValue)) {
        option.val(actionValue[1]).text(actionValue[0]);
        if ($.inArray(actionValue[1], values) > -1) {option.attr('selected', true);}
        if (actionValue.length == 3) {
          var optgroup = select.find('optgroup').filter(function(){return $(this).attr('label') == actionValue[2]});
          if (!optgroup.length) {optgroup = $('<optgroup>').attr('label', actionValue[2]);}
          option = optgroup.append(option);
        }
      } else {
        option.val(actionValue).text(actionValue);
        if ($.inArray(actionValue, values) > -1) {option.attr('selected', true);}
      }
      select.append(option);
    }
    break;
  case "date":
  case "date_past":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="date" name="v['+field+'][]" id="values_'+fieldId+'_1" size="10" class="value date_value" /></span>' +
      ' <span style="display:none;"><input type="date" name="v['+field+'][]" id="values_'+fieldId+'_2" size="10" class="value date_value" /></span>' +
      ' <span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="3" class="value" /> '+labelDayPlural+'</span>'
    );
    $('#values_'+fieldId+'_1').val(values[0]).datepickerFallback(datepickerOptions);
    $('#values_'+fieldId+'_2').val(values[1]).datepickerFallback(datepickerOptions);
    $('#values_'+fieldId).val(values[0]);
    break;
  case "date_with_labels":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="hidden" name="v['+field+'][]" id="values_'+fieldId+'" class="value date_with_labels" /></span>' +
      '<span style="display:none;"><input type="date" name="v['+field+'][]" id="values_'+fieldId+'_1" size="10" class="value date_with_labels" /></span>' +
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_2" size="3" class="value" /> '+labelDayPlural+'</span>'
    );
    $('#values_'+fieldId).val(values[0]);
    $('#values_'+fieldId+'_1').val(values[0]).datepickerFallback(datepickerOptions);
    $('#values_'+fieldId+'_2').val(values[0]);
    break;
  case "string":
  case "text":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="30" class="value" /></span>'
    );
    $('#values_'+fieldId).val(values[0]);
    break;
  case "relation":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="6" class="value" /></span>' +
      '<span style="display:none;"><select class="value" name="v['+field+'][]" id="values_'+fieldId+'_1"></select></span>'
    );
    $('#values_'+fieldId).val(values[0]);
    select = tr.find('td.values select');
    for (i = 0; i < actionValues.length; i++) {
      var filterValue = actionValues[i];
      var option = $('<option>');
      option.val(filterValue[1]).text(filterValue[0]);
      if (values[0] == filterValue[1]) { option.attr('selected', true); }
      select.append(option);
    }
    break;
  case "integer":
  case "float":
  case "tree":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_1" size="14" class="value" /></span>' +
      ' <span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_2" size="14" class="value" /></span>'
    );
    $('#values_'+fieldId+'_1').val(values[0]);
    $('#values_'+fieldId+'_2').val(values[1]);
    break;
  }


  var filter = availableActions[field];
  var options = select2Filters[filter['type']];
  if (options) {
    setSelect2ActionValues(field, options, values);
    transformActionToSelect2(field, options);
  }
}

function toggleActionOperator(field) {
  var fieldId = field.replace('.', '_');
  var operator = $("#operators_" + fieldId);
  switch (operator.val()) {
    case "nd":
    case "t":
      enableActionValues(field, [0]);
      break;
    case "=":
      enableActionValues(field, [1]);
      break;
    case "da":
      enableActionValues(field, [2]);
      break;
    default:
      enableActionValues(field, [0]);
      break;
  }
}

function findActionRowBy(field, selector) {
  return $('#tr_action_' + sanitizeToId(field) + ' ' + selector);
};

function setSelect2ActionValues(field, options, values) {
  var needAddValues = !rowHasSelectTag(field);
  if (needAddValues) { addActionSelectTag(field) }

  var $select = findActionRowBy(field, ' .values select.value');
  if (options['multiple'] !== false) { $select.attr('multiple', true) }

  if (needAddValues) { addActionOptionTags($select, field, values); }
};

function addActionSelectTag(field) {
  var fieldId = sanitizeToId(field);
  $('#tr_action_' + fieldId).find('td.values').append(
    '<span style="display:none;"><select class="value" id="values_'+fieldId+'_1" name="v['+field+'][]"></select></span>'
  );
};

function addActionOptionTags($select, field, values) {
  var filterValues = availableActions[field]['values'];

  for (var i = 0; i < filterValues.length; i++) {
    var filterValue = filterValues[i];
    var option = $('<option>');

    if ($.isArray(filterValue)) {
      option.val(filterValue[1]).text(filterValue[0]);
      if ($.inArray(filterValue[1], values) > -1) { option.attr('selected', true); }
    } else {
      option.val(filterValue).text(filterValue);
      if ($.inArray(filterValue, values) > -1) { option.attr('selected', true); }
    }

    $select.append(option);
  }
};

function transformActionToSelect2(field, options) {
  if (findActionRowBy(field, '.values .select2').length > 0) { return }

  findActionRowBy(field, '.toggle-multiselect').hide();
  findActionRowBy(field, '.values select.value').select2(buildSelect2Options(options));
};

function toogleMailRuleButton() {
  disabled = $('.action input[name="a[]"]:checked').length == 0
  $('.mail-rule-button').prop('name', disabled ? 'continue': 'submit');
  $('.mail-rule-button').prop('disabled', disabled);
};

function toogleAllEmailsLabel() {
  $filters = $('#filters-table .filter')
  $checkedFilters = $('.filter input[name="f[]"]:checked')

  if ($filters.length > 0 && $checkedFilters.length > 0) {
    $('.all-emails-label').hide()
  } else {
    $('.all-emails-label').show()
  }
}

$(document).ready(function(){
  $('#content').on('change', '#add_filter_select', toogleMailRuleButton);
  $('#content').on('change', '#add_action_select', toogleMailRuleButton);
  $('#content').on('change', '.filter input[name="f[]"]', toogleMailRuleButton);
  $('#content').on('change', '.action input[name="a[]"]', toogleMailRuleButton);

  $('#content').on('change', '#add_filter_select', toogleAllEmailsLabel);
  $('#content').on('change', '.filter input[name="f[]"]', toogleAllEmailsLabel);
});

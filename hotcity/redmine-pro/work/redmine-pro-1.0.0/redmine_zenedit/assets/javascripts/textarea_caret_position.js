(function () {
  var properties = [
    'direction',  // RTL support
    'boxSizing',
    'width',  // on Chrome and IE, exclude the scrollbar, so the mirror div wraps exactly as the textarea does
    'height',
    'overflowX',
    'overflowY',  // copy the scrollbar for IE

    'borderTopWidth',
    'borderRightWidth',
    'borderBottomWidth',
    'borderLeftWidth',
    'borderStyle',

    'paddingTop',
    'paddingRight',
    'paddingBottom',
    'paddingLeft',

    // https://developer.mozilla.org/en-US/docs/Web/CSS/font
    'fontStyle',
    'fontVariant',
    'fontWeight',
    'fontStretch',
    'fontSize',
    'fontSizeAdjust',
    'lineHeight',
    'fontFamily',

    'textAlign',
    'textTransform',
    'textIndent',
    'textDecoration',  // might not make a difference, but better be safe

    'letterSpacing',
    'wordSpacing',

    'tabSize',
    'MozTabSize'
  ];

  var isBrowser = (typeof window !== 'undefined');
  var isFirefox = (isBrowser && window.mozInnerScreenX != null);

  window.getCaretCoordinates = function (element, position) {
    // The mirror div will replicate the textarea's style
    var div = document.createElement('div');
    div.id = 'input-textarea-caret-position-mirror-div';
    document.body.appendChild(div);

    var style = div.style;
    var computed = window.getComputedStyle ? window.getComputedStyle(element) : element.currentStyle;  // currentStyle for IE < 9

    // Default textarea styles
    style.whiteSpace = 'pre-wrap';
    style.wordWrap = 'break-word';

    // Position off-screen
    style.position = 'absolute';  // required to return coordinates properly

    // Transfer the element's properties to the div
    properties.forEach(function (prop) {
        style[prop] = computed[prop];
    });

    if (isFirefox) {
      // Firefox lies about the overflow property for textareas: https://bugzilla.mozilla.org/show_bug.cgi?id=984275
      if (element.scrollHeight > parseInt(computed.height))
        style.overflowY = 'scroll';
    } else {
      style.overflow = 'hidden';  // For Chrome to not render a scrollbar; IE keeps overflowY = 'scroll'
    }

    div.textContent = element.value.substring(0, position);
    var span = document.createElement('span');
    // Give the span the textContent of remaining content so that the recreated dummy element is as close as possible
    span.textContent = element.value.substring(position) || '.';  // || because a completely empty faux span doesn't render at all
    div.appendChild(span);

    var height = parseInt(computed['lineHeight']);
    height = isNaN(height) ? parseInt(computed['fontSize']) + 2 : height;
    var coordinates = {
      top: span.offsetTop + parseInt(computed['borderTopWidth']),
      left: span.offsetLeft + parseInt(computed['borderLeftWidth']),
      height: height
    };

    document.body.removeChild(div);
    return coordinates;
  }
}());

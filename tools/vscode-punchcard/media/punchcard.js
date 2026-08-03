// The punchcard webview. Inlined into the page under a nonce, so this file must
// stay dependency free.
//
// The webview holds no copy of the character code: the extension host reads
// every column with the ported §4 rules and sends the result. The webview draws
// punches, tracks the cursor, and sends edit requests back.

(function () {
  'use strict';

  var vscode = acquireVsCodeApi();
  var COLS = 80;
  var ROWS = 12;
  var ROW_NAMES = [
    '12', '11', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];
  var MIN_CW = 9;
  var MAX_CW = 26;

  function el(id) {
    return document.getElementById(id);
  }

  var fieldsEl = el('fields');
  var interpEl = el('interp');
  var numsTensEl = el('numsTens');
  var numsUnitsEl = el('numsUnits');
  var gridEl = el('grid');
  var cardEl = el('card');
  var emptyEl = el('empty');
  var cardWrap = el('cardWrap');
  var cardList = el('cardList');
  var statusEl = el('status');
  var legendEl = el('legend');
  var posEl = el('cardPos');
  var headEl = el('deckHead');
  var typeModeBox = el('typeMode');

  var cells = []; // cells[row][column - 1]
  var interpCells = [];
  var numCells = []; // [tens row, units row][column - 1]

  var st = {
    cardCount: 0,
    index: 0,
    previews: [],
    columns: [],
    readout: [],
    fields: [],
    markers: {},
  };
  var col = 1;
  var row = 3;
  var prevCol = 0;
  var typeMode = false;
  var cw = 15;
  var flashTimer = 0;

  build();
  restore();
  wire();
  vscode.postMessage({ type: 'ready' });

  // --- construction -------------------------------------------------------

  function gut(text) {
    var d = document.createElement('div');
    d.className = 'gut';
    d.textContent = text;
    return d;
  }

  function build() {
    interpEl.appendChild(gut('READS'));
    for (var c = 1; c <= COLS; c++) {
      var ic = document.createElement('div');
      ic.className = 'ic';
      ic.dataset.c = String(c);
      interpEl.appendChild(ic);
      interpCells.push(ic);
    }

    var bands = [numsTensEl, numsUnitsEl];
    for (var b = 0; b < bands.length; b++) {
      bands[b].appendChild(gut(''));
      var line = [];
      for (var n = 1; n <= COLS; n++) {
        var nc = document.createElement('div');
        nc.className = n % 10 === 0 ? 'nc tick' : 'nc';
        nc.textContent =
          b === 0
            ? n >= 10
              ? String(Math.floor(n / 10))
              : ''
            : String(n % 10);
        nc.dataset.c = String(n);
        bands[b].appendChild(nc);
        line.push(nc);
      }
      numCells.push(line);
    }

    for (var r = 0; r < ROWS; r++) {
      var rowEl = document.createElement('div');
      rowEl.className = r < 3 ? 'row z' : 'row';
      rowEl.appendChild(gut(ROW_NAMES[r]));
      var cellLine = [];
      for (var cc = 1; cc <= COLS; cc++) {
        var cell = document.createElement('div');
        cell.className = 'cell';
        cell.textContent = ROW_NAMES[r];
        cell.dataset.c = String(cc);
        cell.dataset.r = String(r);
        rowEl.appendChild(cell);
        cellLine.push(cell);
      }
      cells.push(cellLine);
      gridEl.appendChild(rowEl);
    }
  }

  function buildFields(fields) {
    fieldsEl.textContent = '';
    fieldsEl.appendChild(gut('FIELDS'));
    for (var i = 0; i < fields.length; i++) {
      var f = fields[i];
      var d = document.createElement('div');
      d.className = 'fld';
      d.style.gridColumn =
        String(f.start + 1) + ' / span ' + String(f.end - f.start + 1);
      d.textContent = f.label + ' ' + f.start + '-' + f.end;
      d.title = f.name;
      fieldsEl.appendChild(d);
    }
  }

  function buildLegend() {
    var m = st.markers || {};
    legendEl.textContent =
      'Interpreted row: ' +
      (m.special || '') +
      ' machine special, ' +
      (m.unattested || '') +
      ' unattested code, ' +
      (m.none || '') +
      ' no read-out. ' +
      'Click a cell to punch. Arrows move, Space or Enter punches, ' +
      'PageUp and PageDown change card.';
  }

  // --- state --------------------------------------------------------------

  function restore() {
    var saved = vscode.getState();
    if (saved) {
      cw = clampNum(saved.cw || cw, MIN_CW, MAX_CW);
      typeMode = saved.typeMode === true;
      col = clampNum(saved.col || 1, 1, COLS);
      row = clampNum(saved.row || 3, 0, ROWS - 1);
    }
    typeModeBox.checked = typeMode;
    applyZoom();
  }

  function persist() {
    vscode.setState({ cw: cw, typeMode: typeMode, col: col, row: row });
  }

  function clampNum(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v));
  }

  function applyZoom() {
    document.documentElement.style.setProperty('--cw', cw + 'px');
    document.documentElement.style.setProperty('--ch', cw + 'px');
  }

  window.addEventListener('message', function (event) {
    var m = event.data;
    if (m.type === 'state') {
      onState(m);
    } else if (m.type === 'status') {
      flash(m.text);
    }
  });

  function onState(m) {
    st.cardCount = m.cardCount;
    st.index = m.index;
    st.columns = m.columns || [];
    st.readout = m.readout || [];
    if (m.fields && m.fields.length) {
      st.fields = m.fields;
      buildFields(m.fields);
    }
    if (m.markers) {
      st.markers = m.markers;
      buildLegend();
    }
    if (m.previews) {
      st.previews = m.previews;
      rebuildList();
    } else if (m.preview) {
      st.previews[m.preview.index] = m.preview.text;
      patchList(m.preview.index, m.preview.text);
    }
    if (typeof m.cursor === 'number') {
      col = clampNum(m.cursor, 1, COLS);
    }
    render();
  }

  function rebuildList() {
    cardList.textContent = '';
    var frag = document.createDocumentFragment();
    for (var i = 0; i < st.previews.length; i++) {
      var li = document.createElement('li');
      li.dataset.i = String(i);
      var num = document.createElement('span');
      num.className = 'num';
      num.textContent = String(i + 1);
      var txt = document.createElement('span');
      txt.className = 'txt';
      txt.textContent = st.previews[i];
      li.appendChild(num);
      li.appendChild(txt);
      frag.appendChild(li);
    }
    cardList.appendChild(frag);
  }

  function patchList(index, text) {
    var li = cardList.children[index];
    if (li) {
      li.children[1].textContent = text;
    }
  }

  // --- rendering ----------------------------------------------------------

  function render() {
    headEl.textContent =
      'Deck - ' + st.cardCount + (st.cardCount === 1 ? ' card' : ' cards');
    posEl.textContent =
      st.cardCount === 0
        ? 'no cards'
        : 'card ' + (st.index + 1) + ' / ' + st.cardCount;
    var empty = st.cardCount === 0;
    cardEl.classList.toggle('hidden', empty);
    emptyEl.classList.toggle('hidden', !empty);

    for (var i = 0; i < cardList.children.length; i++) {
      cardList.children[i].classList.toggle('sel', i === st.index);
    }
    var sel = cardList.children[st.index];
    if (sel && sel.scrollIntoView) {
      sel.scrollIntoView({ block: 'nearest' });
    }

    if (!empty) {
      for (var c = 0; c < COLS; c++) {
        var punches = st.columns[c] | 0;
        for (var r = 0; r < ROWS; r++) {
          var on = (punches & (1 << (11 - r))) !== 0;
          cells[r][c].classList.toggle('on', on);
        }
        var ro = st.readout[c] || { ch: ' ', kind: 'blank', code: '', octal: '', name: '' };
        var ic = interpCells[c];
        ic.textContent = ro.ch;
        ic.className = 'ic k-' + ro.kind;
        ic.title = tip(c + 1, ro);
      }
    }
    highlight();
    showStatus(statusText(), false);
    persist();
  }

  function tip(column, ro) {
    var parts = ['col ' + column];
    parts.push(ro.code === '' ? 'no punches' : ro.code);
    if (ro.octal !== '') {
      parts.push('octal ' + ro.octal);
    }
    parts.push(ro.name);
    return parts.join(' | ');
  }

  function highlight() {
    if (prevCol >= 1) {
      setColClass(prevCol, false);
    }
    setColClass(col, true);
    prevCol = col;
    for (var r = 0; r < ROWS; r++) {
      for (var c = 0; c < COLS; c++) {
        var want = r === row && c === col - 1;
        if (cells[r][c].classList.contains('cur-cell') !== want) {
          cells[r][c].classList.toggle('cur-cell', want);
        }
      }
    }
  }

  function setColClass(column, on) {
    var c = column - 1;
    if (c < 0 || c >= COLS) {
      return;
    }
    interpCells[c].classList.toggle('col-cur', on);
    numCells[0][c].classList.toggle('col-cur', on);
    numCells[1][c].classList.toggle('col-cur', on);
    for (var r = 0; r < ROWS; r++) {
      cells[r][c].classList.toggle('col-cur', on);
    }
  }

  function fieldOf(column) {
    for (var i = 0; i < st.fields.length; i++) {
      if (column >= st.fields[i].start && column <= st.fields[i].end) {
        return st.fields[i];
      }
    }
    return { name: '?' };
  }

  function statusText() {
    if (st.cardCount === 0) {
      return 'The deck is empty.';
    }
    var ro = st.readout[col - 1];
    if (!ro) {
      return '';
    }
    var parts = [
      'card ' + (st.index + 1),
      'col ' + col + ' (' + fieldOf(col).name + ')',
      ro.code === '' ? 'no punches' : 'code ' + ro.code,
    ];
    if (ro.octal !== '') {
      parts.push('octal ' + ro.octal);
    }
    parts.push(ro.name);
    parts.push(typeMode ? 'type to punch' : 'row ' + ROW_NAMES[row]);
    return parts.join('  .  ');
  }

  function showStatus(text, warn) {
    statusEl.textContent = text;
    statusEl.classList.toggle('warn', warn === true);
  }

  function flash(text) {
    showStatus(text, true);
    if (flashTimer) {
      clearTimeout(flashTimer);
    }
    flashTimer = setTimeout(function () {
      showStatus(statusText(), false);
    }, 2500);
  }

  // --- editing ------------------------------------------------------------

  function moveTo(column, rowIndex) {
    col = clampNum(column, 1, COLS);
    if (typeof rowIndex === 'number') {
      row = clampNum(rowIndex, 0, ROWS - 1);
    }
    highlight();
    showStatus(statusText(), false);
    persist();
    scrollColumnIntoView();
  }

  function scrollColumnIntoView() {
    var cell = cells[row][col - 1];
    if (cell && cell.scrollIntoView) {
      cell.scrollIntoView({ block: 'nearest', inline: 'nearest' });
    }
  }

  function toggleAt(column, rowIndex) {
    if (st.cardCount === 0) {
      return;
    }
    vscode.postMessage({
      type: 'toggle',
      index: st.index,
      column: column,
      row: rowIndex,
    });
  }

  function clearColumn(column) {
    if (st.cardCount === 0) {
      return;
    }
    vscode.postMessage({
      type: 'setColumn',
      index: st.index,
      column: column,
      punches: 0,
    });
  }

  function selectCard(index) {
    vscode.postMessage({ type: 'select', index: index });
  }

  function wire() {
    cardList.addEventListener('click', function (e) {
      var li = e.target.closest ? e.target.closest('li') : null;
      if (li && li.dataset.i !== undefined) {
        selectCard(Number(li.dataset.i));
        focusCard();
      }
    });

    gridEl.addEventListener('click', function (e) {
      var t = e.target;
      if (!t.classList || !t.classList.contains('cell')) {
        return;
      }
      var c = Number(t.dataset.c);
      var r = Number(t.dataset.r);
      moveTo(c, r);
      toggleAt(c, r);
      focusCard();
    });

    function pick(e) {
      var t = e.target;
      if (t.dataset && t.dataset.c !== undefined) {
        moveTo(Number(t.dataset.c));
        focusCard();
      }
    }
    interpEl.addEventListener('click', pick);
    numsTensEl.addEventListener('click', pick);
    numsUnitsEl.addEventListener('click', pick);

    el('btnPrev').addEventListener('click', function () {
      selectCard(st.index - 1);
      focusCard();
    });
    el('btnNext').addEventListener('click', function () {
      selectCard(st.index + 1);
      focusCard();
    });
    el('btnAdd').addEventListener('click', function () {
      vscode.postMessage({ type: 'insert', index: st.index });
      focusCard();
    });
    el('btnDup').addEventListener('click', function () {
      vscode.postMessage({ type: 'duplicate', index: st.index });
      focusCard();
    });
    el('btnDel').addEventListener('click', function () {
      vscode.postMessage({ type: 'delete', index: st.index });
      focusCard();
    });
    el('zoomIn').addEventListener('click', function () {
      cw = clampNum(cw + 2, MIN_CW, MAX_CW);
      applyZoom();
      persist();
      focusCard();
    });
    el('zoomOut').addEventListener('click', function () {
      cw = clampNum(cw - 2, MIN_CW, MAX_CW);
      applyZoom();
      persist();
      focusCard();
    });
    typeModeBox.addEventListener('change', function () {
      typeMode = typeModeBox.checked;
      showStatus(statusText(), false);
      persist();
      focusCard();
    });

    document.addEventListener('keydown', onKey);
    focusCard();
  }

  function focusCard() {
    cardWrap.focus({ preventScroll: true });
  }

  function onKey(e) {
    if (e.ctrlKey || e.metaKey || e.altKey) {
      return; // Leave undo, save and the rest to VS Code.
    }
    var k = e.key;
    if (k === 'ArrowLeft') {
      moveTo(col - 1);
    } else if (k === 'ArrowRight') {
      moveTo(col + 1);
    } else if (k === 'ArrowUp') {
      moveTo(col, row - 1);
    } else if (k === 'ArrowDown') {
      moveTo(col, row + 1);
    } else if (k === 'Home') {
      moveTo(1);
    } else if (k === 'End') {
      moveTo(COLS);
    } else if (k === 'PageUp') {
      selectCard(st.index - 1);
    } else if (k === 'PageDown') {
      selectCard(st.index + 1);
    } else if (k === 'Backspace') {
      if (col > 1) {
        moveTo(col - 1);
      }
      clearColumn(col);
    } else if (k === 'Delete') {
      clearColumn(col);
    } else if (k === 'Enter') {
      toggleAt(col, row);
    } else if (k === ' ' && !typeMode) {
      toggleAt(col, row);
    } else if (typeMode && k.length === 1) {
      vscode.postMessage({
        type: 'typeGlyph',
        index: st.index,
        column: col,
        glyph: k,
      });
    } else {
      return;
    }
    e.preventDefault();
    e.stopPropagation();
  }
})();

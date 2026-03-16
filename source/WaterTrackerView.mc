// WaterTrackerView.mc — split layout: левая = данные, правая = прокручиваемые кнопки
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Timer;
import Toybox.WatchUi;

const ZONE_NONE        as Number = -1;
const ZONE_SLOT0       as Number = 0;
const ZONE_SLOT1       as Number = 1;
const ZONE_SLOT2       as Number = 2;
const ZONE_SLOT3       as Number = 3;
const ZONE_SCROLL_UP   as Number = 5;
const ZONE_SCROLL_DOWN as Number = 6;
const ZONE_WARNING     as Number = 7;
const ZONE_REC         as Number = 8;

const RIGHT_ITEM_COUNT as Number = 6;

class WaterTrackerView extends WatchUi.View {

    private var _btnX        as Number = 0;
    private var _btnW        as Number = 0;
    private var _btnH        as Number = 0;
    private var _arrowH      as Number = 0;
    private var _scrollUpY   as Number = 0;
    private var _scrollDownY as Number = 0;
    private var _slotY       as Array<Number>;

    private var _scrollTop  as Number = 0;
    private var _activeZone as Number = ZONE_NONE;
    private var _timer      as Timer.Timer;

    // Позиция иконки предупреждения и REC строки (левая часть)
    private var _warnX as Number = 0;
    private var _warnY as Number = 0;
    private var _warnR as Number = 0;
    private var _recY  as Number = 0;

    private var _itemLabels as Array<String>;
    private var _itemColors as Array<Number>;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
        _slotY = new [4] as Array<Number>;
        _itemLabels = ["-100", "+100", "+250", "+500", "+/-", "Reset"] as Array<String>;
        _itemColors = [0xB71C1C, 0x0D47A1, 0x1565C0, 0x1976D2, 0xF57F17, 0x37474F] as Array<Number>;
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function getScrollTop() as Number { return _scrollTop; }
    function getBtnX()     as Number { return _btnX; }

    function scrollUp() as Void {
        _scrollTop = (_scrollTop + RIGHT_ITEM_COUNT - 1) % RIGHT_ITEM_COUNT;
        WatchUi.requestUpdate();
    }

    function scrollDown() as Void {
        _scrollTop = (_scrollTop + 1) % RIGHT_ITEM_COUNT;
        WatchUi.requestUpdate();
    }

    function flashZone(zone as Number) as Void {
        _activeZone = zone;
        WatchUi.requestUpdate();
        _timer.start(method(:clearFlash), 400, false);
    }

    function clearFlash() as Void {
        _activeZone = ZONE_NONE;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        var amount  = DataStore.getAmount();
        var goal    = DataStore.getGoal();
        var rec     = DataStore.getRecommendedGoal();
        var units   = DataStore.getUnits();
        var unitLbl = (units == 0) ? "ml" : "oz";
        var goalReached = (amount >= goal);
        var recReached  = (amount >= rec);
        var profileIncomplete = DataStore.isProfileIncomplete();

        // Цвета по новой логике:
        // < goal: TODAY белый, GOAL серый, REC серый
        // >= goal: TODAY оранжевый, GOAL оранжевый, REC серый
        // >= rec:  TODAY зелёный, GOAL зелёный, REC зелёный
        var minTarget = (goal < rec) ? goal : rec;
        var maxTarget = (goal > rec) ? goal : rec;
        var pctOfRec = (rec > 0) ? (amount * 100 / rec) : 0;
        var amountColor; var goalColor; var recColor;
        if (recReached) {
            amountColor = 0x1565C0;  // синий — REC достигнут
            goalColor   = 0x43A047;  // зелёный — GOAL тоже достигнут
            recColor    = 0x1565C0;  // синий
        } else if (goalReached) {
            amountColor = 0x43A047;  // зелёный — GOAL достигнут
            goalColor   = 0x43A047;
            recColor    = 0x3A3A3A;
        } else if (pctOfRec >= 33) {
            amountColor = 0xFF8F00;  // оранжевый
            goalColor   = 0x707070;
            recColor    = 0x3A3A3A;
        } else {
            amountColor = 0xE0E0E0;  // белый — 0–33%, начало дня
            goalColor   = 0x707070;
            recColor    = 0x3A3A3A;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Разделитель по центру (тонкая линия) ─────────────
        var divX  = w / 2;
        dc.setColor(0x3A3A3A, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(divX, h * 8 / 100, divX, h * 78 / 100);

        // ── Горизонтальный прогресс бар внизу ────────────────
        // Динамический расчёт ширины под любой круглый экран
        var hBarY = h * 84 / 100;
        var hBarH = 10;
        var hBarR = hBarH / 2;
        var radius   = w / 2;
        var barMidY  = hBarY + hBarH / 2;
        var dist     = barMidY - h / 2;
        var halfW    = Math.sqrt((radius * radius - dist * dist).toFloat()).toNumber();
        var hBarX = w / 2 - halfW + 8;
        var hBarW = (halfW - 8) * 2;

        // Фон бара
        dc.setColor(0x050A10, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(hBarX, hBarY, hBarW, hBarH, hBarR);
        dc.setColor(0x0F1E2A, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(hBarX, hBarY, hBarW, hBarH, hBarR);

        // Заливка слева направо — светофор по % от REC
        var pct     = (rec > 0) ? (amount * 100 / rec) : 0;
        var fillPct = (maxTarget > 0) ? (amount * 100 / maxTarget) : 0;
        if (fillPct > 100) { fillPct = 100; }
        var fillW = hBarW * fillPct / 100;
        if (fillW > 0) {
            var fillColor;
            if (recReached)       { fillColor = 0x1565C0; }  // синий — REC!
            else if (goalReached) { fillColor = 0x43A047; }  // зелёный — GOAL
            else if (pct >= 33)   { fillColor = 0xFF8F00; }  // оранжевый
            else                  { fillColor = 0xE0E0E0; }  // белый — 0–33%
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            if (fillW >= hBarH) {
                dc.fillRoundedRectangle(hBarX, hBarY, fillW, hBarH, hBarR);
            } else {
                dc.fillRectangle(hBarX, hBarY, fillW, hBarH);
            }
        }

        // Метка первой цели
        if (goal != rec && maxTarget > 0) {
            var tickX = hBarX + (hBarW * minTarget / maxTarget);
            dc.setColor(0x2E3F50, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(tickX, hBarY, 2, hBarH);
        }

        // ── Левая часть ───────────────────────────────────────
        var rightX = divX - 6;
        var jRight = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(recReached ? 0xFFFFFF : 0x4A4A4A, Graphics.COLOR_TRANSPARENT);
        var topLabel = recReached ? "DONE!" : "TODAY";
        dc.drawText(rightX, h * 18 / 100, Graphics.FONT_XTINY, topLabel, jRight);

        // Число + единица в одну строку (единица вплотную к бару, число левее)
        var numY   = h * 32 / 100;
        var numStr = _fmtNum(amount, units);
        var unitW  = dc.getTextWidthInPixels(unitLbl, Graphics.FONT_XTINY);
        dc.setColor(amountColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, numY, Graphics.FONT_XTINY, unitLbl, jRight);
        dc.setColor(amountColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX - unitW - 3, numY, Graphics.FONT_LARGE, numStr, jRight);

        // GOAL
        dc.setColor(goalColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, h * 50 / 100, Graphics.FONT_TINY,
            "GOAL  " + _fmtNum(goal, units), jRight);

        // REC + предупреждение (если профиль неполный)
        _warnR = 0;
        var recY = h * 68 / 100;
        _recY  = recY;
        _warnY = recY;
        if (profileIncomplete) {
            _warnR = 5;
            _warnX = 14;
            dc.setColor(0x4A4A4A, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightX, recY, Graphics.FONT_TINY,
                "REC  " + _fmtNum(rec, units), jRight);
            dc.setColor(0xFFB300, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_warnX, _warnY, _warnR);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_warnX, _warnY, Graphics.FONT_XTINY, "!",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(recColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightX, recY, Graphics.FONT_TINY,
                "REC  " + _fmtNum(rec, units), jRight);
        }

        // ── Правая часть: прокручиваемые кнопки ──────────
        _btnX = divX + 5;
        _btnW = w - _btnX - 6;
        _arrowH = h * 6 / 100;
        _btnH   = h * 13 / 100;
        var gap = h * 3 / 100;

        var areaTop  = h * 14 / 100;
        _scrollUpY   = areaTop;
        _slotY[0]    = areaTop + _arrowH;
        _slotY[1]    = _slotY[0] + _btnH + gap;
        _slotY[2]    = _slotY[1] + _btnH + gap;
        _slotY[3]    = _slotY[2] + _btnH + gap;
        _scrollDownY = _slotY[3] + _btnH;

        // Стрелка вверх
        var ax  = _btnX + _btnW / 2;
        var ayu = _scrollUpY + _arrowH / 2;
        dc.setColor(0x5A5A5A, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(ax - 7, ayu + 3, ax,     ayu - 3);
        dc.drawLine(ax,     ayu - 3, ax + 7, ayu + 3);
        dc.drawLine(ax - 6, ayu + 3, ax,     ayu - 2);
        dc.drawLine(ax,     ayu - 2, ax + 6, ayu + 3);

        // 4 видимых кнопки
        for (var slot = 0; slot < 4; slot++) {
            var itemIdx = (_scrollTop + slot) % RIGHT_ITEM_COUNT;
            _drawBtn(dc, _btnX, _slotY[slot], _btnW, _btnH,
                _itemLabels[itemIdx], slot, _itemColors[itemIdx]);
        }

        // Стрелка вниз
        var ayd = _scrollDownY + _arrowH / 2;
        dc.setColor(0x5A5A5A, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(ax - 7, ayd - 3, ax,     ayd + 3);
        dc.drawLine(ax,     ayd + 3, ax + 7, ayd - 3);
        dc.drawLine(ax - 6, ayd - 3, ax,     ayd + 2);
        dc.drawLine(ax,     ayd + 2, ax + 6, ayd - 3);
    }

    function getZoneForTap(tapX as Number, tapY as Number) as Number {
        // Иконка предупреждения на левой стороне
        if (_warnR > 0 && tapX < _btnX) {
            var dx = tapX - _warnX;
            var dy = tapY - _warnY;
            if (dx * dx + dy * dy <= (_warnR + 6) * (_warnR + 6)) {
                return ZONE_WARNING;
            }
        }
        // Строка REC на левой части — установить базовую цель
        if (_warnR == 0 && tapX < _btnX && _recY > 0) {
            if (tapY >= _recY - 16 && tapY <= _recY + 16) {
                return ZONE_REC;
            }
        }
        if (tapX < _btnX) { return ZONE_NONE; }
        if (tapY >= _scrollUpY && tapY < _slotY[0]) {
            return ZONE_SCROLL_UP;
        }
        if (tapY >= _scrollDownY && tapY < _scrollDownY + _arrowH) {
            return ZONE_SCROLL_DOWN;
        }
        for (var slot = 0; slot < 4; slot++) {
            if (tapY >= _slotY[slot] && tapY <= _slotY[slot] + _btnH) {
                return slot;
            }
        }
        return ZONE_NONE;
    }

    private function _drawBtn(
        dc        as Graphics.Dc,
        x         as Number, y as Number,
        w         as Number, h as Number,
        label     as String,
        zone      as Number,
        baseColor as Number
    ) as Void {
        var isActive = (_activeZone == zone);
        var r = 10;

        if (isActive) {
            // Нажато: белая вспышка
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, w, h, r);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            // Обычное: насыщенный цвет, чистая заливка
            dc.setColor(baseColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, w, h, r);
            dc.setColor(0xE0E0E0, Graphics.COLOR_TRANSPARENT);
        }

        dc.drawText(x + w / 2, y + h / 2, Graphics.FONT_TINY,
            label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _fmtNum(ml as Number, units as Number) as String {
        if (units == 0) { return ml.toString(); }
        return (ml.toFloat() / 29.5735f).format("%.1f");
    }
}

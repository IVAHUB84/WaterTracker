// WaterTrackerView.mc — split layout: левая = данные, правая = прокручиваемые кнопки
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

const ZONE_NONE        as Number = -1;
const ZONE_SLOT0       as Number = 0;
const ZONE_SLOT1       as Number = 1;
const ZONE_SLOT2       as Number = 2;
const ZONE_SLOT3       as Number = 3;
const ZONE_SCROLL_UP   as Number = 5;
const ZONE_SCROLL_DOWN as Number = 6;

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

    private var _itemLabels as Array<String>;
    private var _itemColors as Array<Number>;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
        _slotY = new [4] as Array<Number>;
        _itemLabels = ["-100", "+100", "+250", "+500", "+/-", "Reset"] as Array<String>;
        _itemColors = [0xA93226, 0x1A5E8A, 0x1F7DB5, 0x2196CF, 0x148F77, 0x5D6D7E] as Array<Number>;
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
        var units   = DataStore.getUnits();
        var unitLbl = (units == 0) ? "ml" : "oz";
        var reached = (amount >= goal);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Разделитель ──────────────────────────────────
        var divX = w / 2;
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(divX, h * 12 / 100, divX, h * 88 / 100);

        // ── Левая часть ───────────────────────────────────
        var leftCx = divX / 2;

        dc.setColor(0x777777, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, h * 20 / 100, Graphics.FONT_XTINY,
            "GOAL",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, h * 32 / 100, Graphics.FONT_SMALL,
            _fmtNum(goal, units) + " " + unitLbl,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(leftCx - 28, h * 50 / 100, leftCx + 28, h * 50 / 100);

        dc.setColor(0x777777, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, h * 60 / 100, Graphics.FONT_XTINY,
            "TODAY",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(
            reached ? Graphics.COLOR_GREEN : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, h * 73 / 100, Graphics.FONT_SMALL,
            _fmtNum(amount, units) + " " + unitLbl,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Правая часть: прокручиваемые кнопки ──────────
        _btnX = divX + 4;
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

        // Стрелка вверх — жирная двойная
        var ax  = _btnX + _btnW / 2;
        var ayu = _scrollUpY + _arrowH / 2;
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(ax - 8, ayu + 4, ax,     ayu - 4);
        dc.drawLine(ax,     ayu - 4, ax + 8, ayu + 4);
        dc.drawLine(ax - 7, ayu + 4, ax,     ayu - 3);
        dc.drawLine(ax,     ayu - 3, ax + 7, ayu + 4);

        // 4 видимых кнопки
        for (var slot = 0; slot < 4; slot++) {
            var itemIdx = (_scrollTop + slot) % RIGHT_ITEM_COUNT;
            _drawBtn(dc, _btnX, _slotY[slot], _btnW, _btnH,
                _itemLabels[itemIdx], slot, _itemColors[itemIdx]);
        }

        // Стрелка вниз — жирная двойная
        var ayd = _scrollDownY + _arrowH / 2;
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(ax - 8, ayd - 4, ax,     ayd + 4);
        dc.drawLine(ax,     ayd + 4, ax + 8, ayd - 4);
        dc.drawLine(ax - 7, ayd - 4, ax,     ayd + 3);
        dc.drawLine(ax,     ayd + 3, ax + 7, ayd - 4);
    }

    function getZoneForTap(tapX as Number, tapY as Number) as Number {
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
        var r = 10;   // умеренное скругление — современный "card" стиль

        if (isActive) {
            // Нажато: яркий белый фон + цветное кольцо снаружи
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, w, h, r);
            dc.setColor(baseColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(x - 2, y - 2, w + 4, h + 4, r + 2);
            dc.drawRoundedRectangle(x - 1, y - 1, w + 2, h + 2, r + 1);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            // Обычное: цветная заливка, без бордера
            dc.setColor(baseColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, w, h, r);
            // Тонкий блик — полоска сверху чуть светлее
            dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x + r, y + 1, x + w - r, y + 1);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
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

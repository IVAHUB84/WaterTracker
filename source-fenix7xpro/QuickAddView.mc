// QuickAddView.mc — экран ручного ввода объёма шагом 50 мл
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const QA_STEP    as Number = 50;
const QA_MIN     as Number = -2000;
const QA_MAX     as Number = 2000;
const QA_DEFAULT as Number = 0;

const QA_ZONE_NONE  as Number = -1;
const QA_ZONE_MINUS as Number = 0;
const QA_ZONE_PLUS  as Number = 1;
const QA_ZONE_ADD   as Number = 2;

function pushQuickAddView() as Void {
    var view = new QuickAddView();
    WatchUi.pushView(view, new QuickAddDelegate(view), WatchUi.SLIDE_UP);
}

// =============================================================================
class QuickAddView extends WatchUi.View {

    private var _value as Number = QA_DEFAULT;

    var btnSplitY as Number = 0;
    var btnAddY   as Number = 0;
    var centerX   as Number = 0;

    function initialize() {
        View.initialize();
    }

    function getValue() as Number { return _value; }

    function step(delta as Number) as Void {
        _value += delta;
        if (_value < QA_MIN) { _value = QA_MIN; }
        if (_value > QA_MAX) { _value = QA_MAX; }
        WatchUi.requestUpdate();
    }

    function getZone(tapX as Number, tapY as Number) as Number {
        if (tapY >= btnAddY)   { return QA_ZONE_ADD; }
        if (tapY >= btnSplitY) {
            return (tapX < centerX) ? QA_ZONE_MINUS : QA_ZONE_PLUS;
        }
        return QA_ZONE_NONE;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        centerX   = w / 2;
        btnSplitY = h * 42 / 100;
        btnAddY   = h * 70 / 100;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var jC = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // ── Заголовок ─────────────────────────────────────────
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 10 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.TitleCustomAmount) as String, jC);

        // ── Счётчик по центру ─────────────────────────────────
        var units   = DataStore.getUnits();
        var unitLbl = (units == 0)
            ? (WatchUi.loadResource(Rez.Strings.UnitMl) as String)
            : (WatchUi.loadResource(Rez.Strings.UnitOz) as String);
        var valStr  = (units == 0)
            ? _value.toString()
            : (_value.toFloat() / 29.5735f).format("%.0f");
        var valColor = _value < 0 ? 0xD50000 : Graphics.COLOR_WHITE;
        var numY  = h * 27 / 100;
        var numW  = dc.getTextWidthInPixels(valStr, Graphics.FONT_NUMBER_MEDIUM);
        var unitW = dc.getTextWidthInPixels(unitLbl, Graphics.FONT_SMALL);
        var totalW = numW + 4 + unitW;
        var startX = w / 2 - totalW / 2;
        dc.setColor(valColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, numY, Graphics.FONT_NUMBER_MEDIUM, valStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(startX + numW + 4, numY + 4, Graphics.FONT_SMALL, unitLbl,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Кнопки −50 / +50 (pill-shape) ────────────────────
        var btnH  = h * 22 / 100;
        var btnR  = btnH / 2;
        var gap   = w * 4 / 100;
        var margin = w * 6 / 100;
        var btnW  = (w - 2 * margin - gap) / 2;
        var leftX  = margin;
        var rightX = margin + btnW + gap;

        dc.setColor(0xB71C1C, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(leftX, btnSplitY, btnW, btnH, btnR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX + btnW / 2, btnSplitY + btnH / 2, Graphics.FONT_MEDIUM, "-50", jC);

        dc.setColor(0x1F618D, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(rightX, btnSplitY, btnW, btnH, btnR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX + btnW / 2, btnSplitY + btnH / 2, Graphics.FONT_MEDIUM, "+50", jC);

        // ── Кнопка Add (широкая таблетка) ────────────────────
        var addH = h * 20 / 100;
        var addR = addH / 2;
        var addX = w * 18 / 100;
        var addW = w * 64 / 100;
        dc.setColor(0x1E8449, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(addX, btnAddY, addW, addH, addR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, btnAddY + addH / 2, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.BtnAdd) as String, jC);
    }
}

// =============================================================================
class QuickAddDelegate extends WatchUi.BehaviorDelegate {

    private var _view as QuickAddView;

    function initialize(view as QuickAddView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var zone   = _view.getZone(coords[0], coords[1]);
        if      (zone == QA_ZONE_MINUS) { _view.step(-QA_STEP); }
        else if (zone == QA_ZONE_PLUS)  { _view.step(QA_STEP); }
        else if (zone == QA_ZONE_ADD)   {
            DataStore.addAmount(_view.getValue());
            updateComplications();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onHold(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        if (_view.getZone(coords[0], coords[1]) == QA_ZONE_ADD) {
            DataStore.addAmount(_view.getValue());
            updateComplications();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// GoalPickerView.mc — экран быстрой установки дневной цели
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const GP_STEP_MINUS as Number = 100;
const GP_STEP_PLUS  as Number = 100;
const GP_MIN        as Number = 500;
const GP_MAX        as Number = 10000;

const GP_ZONE_NONE  as Number = -1;
const GP_ZONE_MINUS as Number = 0;
const GP_ZONE_PLUS  as Number = 1;
const GP_ZONE_SET   as Number = 2;

function pushGoalPickerView() as Void {
    var view = new GoalPickerView();
    WatchUi.pushView(view, new GoalPickerDelegate(view), WatchUi.SLIDE_UP);
}

// =============================================================================
class GoalPickerView extends WatchUi.View {

    private var _value as Number;

    var btnSplitY as Number = 0;
    var btnSetY   as Number = 0;
    var centerX   as Number = 0;

    function initialize() {
        View.initialize();
        _value = DataStore.getGoal();
    }

    function getValue() as Number { return _value; }

    function step(delta as Number) as Void {
        _value += delta;
        if (_value < GP_MIN) { _value = GP_MIN; }
        if (_value > GP_MAX) { _value = GP_MAX; }
        WatchUi.requestUpdate();
    }

    function getZone(tapX as Number, tapY as Number) as Number {
        if (tapY >= btnSetY)   { return GP_ZONE_SET; }
        if (tapY >= btnSplitY) {
            return (tapX < centerX) ? GP_ZONE_MINUS : GP_ZONE_PLUS;
        }
        return GP_ZONE_NONE;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        centerX   = w / 2;
        btnSplitY = h * 40 / 100;
        btnSetY   = h * 72 / 100;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Заголовок ────────────────────────────────────────
        dc.setColor(0x777777, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 10 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.SettingGoal) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Текущее значение ─────────────────────────────────
        var units   = DataStore.getUnits();
        var unitLbl = " " + ((units == 0)
            ? (WatchUi.loadResource(Rez.Strings.UnitMl) as String)
            : (WatchUi.loadResource(Rez.Strings.UnitOz) as String));
        var valStr  = (units == 0)
            ? _value.toString()
            : (_value.toFloat() / 29.5735f).format("%.0f");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 27 / 100, Graphics.FONT_MEDIUM,
            valStr + unitLbl,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Кнопки −100 / +100 (pill-shape) ──────────────────
        var btnH  = h * 25 / 100;
        var btnR  = btnH / 2;
        var gap   = w * 4 / 100;
        var margin = w * 6 / 100;
        var btnW  = (w - 2 * margin - gap) / 2;
        var leftX  = margin;
        var rightX = margin + btnW + gap;

        var stepLbl = (units == 0)
            ? "100"
            : (GP_STEP_MINUS.toFloat() / 29.5735f).format("%.0f");
        dc.setColor(0xB71C1C, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(leftX, btnSplitY, btnW, btnH, btnR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX + btnW / 2, btnSplitY + btnH / 2, Graphics.FONT_SMALL,
            "-" + stepLbl,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x1F618D, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(rightX, btnSplitY, btnW, btnH, btnR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX + btnW / 2, btnSplitY + btnH / 2, Graphics.FONT_SMALL,
            "+" + stepLbl,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Кнопка Set (широкая таблетка) ────────────────────
        var setH = h * 20 / 100;
        var setR = setH / 2;
        var setX = w * 18 / 100;
        var setW = w * 64 / 100;
        dc.setColor(0x1E8449, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(setX, btnSetY, setW, setH, setR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, btnSetY + setH / 2, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.BtnSet) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// =============================================================================
class GoalPickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as GoalPickerView;

    function initialize(view as GoalPickerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var zone   = _view.getZone(coords[0], coords[1]);
        if      (zone == GP_ZONE_MINUS) { _view.step(-GP_STEP_MINUS); }
        else if (zone == GP_ZONE_PLUS)  { _view.step(GP_STEP_PLUS); }
        else if (zone == GP_ZONE_SET)   {
            DataStore.setGoal(_view.getValue(), true);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

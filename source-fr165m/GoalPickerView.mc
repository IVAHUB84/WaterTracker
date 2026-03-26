// GoalPickerView.mc — экран установки дневной цели (кнопочная навигация)
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const GP_STEP as Number = 100;
const GP_MIN  as Number = 500;
const GP_MAX  as Number = 10000;

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

    var topZoneH as Number = 0;
    var centerX  as Number = 0;
    private var h as Number = 0;

    function initialize() {
        View.initialize();
        var goalMl = DataStore.getGoal();
        if (DataStore.getUnits() == 1) {
            _value = (goalMl.toFloat() / 29.5735f).toNumber();
        } else {
            _value = goalMl;
        }
    }

    function getValue() as Number {
        if (DataStore.getUnits() == 1) {
            return (_value.toFloat() * 29.5735f).toNumber();
        }
        return _value;
    }

    function step(delta as Number) as Void {
        var isOz = (DataStore.getUnits() == 1);
        _value += delta;
        var minV = isOz ? 17 : GP_MIN;
        var maxV = isOz ? 338 : GP_MAX;
        if (_value < minV) { _value = minV; }
        if (_value > maxV) { _value = maxV; }
        WatchUi.requestUpdate();
    }

    function getZone(tapX as Number, tapY as Number) as Number {
        if (tapY < topZoneH)      { return GP_ZONE_PLUS; }
        if (tapY >= h - topZoneH) { return GP_ZONE_MINUS; }
        return GP_ZONE_SET;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        h        = dc.getHeight();
        centerX  = w / 2;
        topZoneH = h * 28 / 100;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var jC = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var jL = Graphics.TEXT_JUSTIFY_LEFT   | Graphics.TEXT_JUSTIFY_VCENTER;

        // ── Заголовок ─────────────────────────────────────────
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 9 / 100, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.SettingGoal) as String, jC);

        // Безопасные X для круглого экрана
        var upY    = h * 49 / 100;
        var downY  = h * 75 / 100;
        var addLY  = h * 28 / 100;
        var radius = w / 2;
        var upDy   = upY   - h / 2;
        var dnDy   = downY - h / 2;
        var adDy   = addLY - h / 2;
        var upSafeX  = radius - Math.sqrt((radius*radius - upDy*upDy).toFloat()).toNumber() + 10;
        var dnSafeX  = radius - Math.sqrt((radius*radius - dnDy*dnDy).toFloat()).toNumber() + 10;
        var adSafeRX = radius + Math.sqrt((radius*radius - adDy*adDy).toFloat()).toNumber() - 10;

        // ── +шаг слева напротив кнопки UP ────────────────────
        var units2  = DataStore.getUnits();
        var stepLbl = (units2 == 0) ? GP_STEP.toString() : "8";
        dc.setColor(0x1F618D, Graphics.COLOR_TRANSPARENT);
        dc.drawText(upSafeX, upY, Graphics.FONT_LARGE, "+" + stepLbl, jL);

        // ── -шаг слева напротив кнопки DOWN ──────────────────
        dc.setColor(0xB71C1C, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dnSafeX, downY, Graphics.FONT_LARGE, "-" + stepLbl, jL);

        // ── Установить — справа напротив кнопки SELECT ────────
        dc.setColor(0x5A9E6F, Graphics.COLOR_TRANSPARENT);
        dc.drawText(adSafeRX, addLY, Graphics.FONT_LARGE,
            WatchUi.loadResource(Rez.Strings.BtnSet) as String,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Значение правее центра ────────────────────────────
        var units   = DataStore.getUnits();
        var unitLbl = (units == 0)
            ? (WatchUi.loadResource(Rez.Strings.UnitMl) as String)
            : (WatchUi.loadResource(Rez.Strings.UnitOz) as String);
        var valStr  = _value.toString();
        var valX     = w * 63 / 100;
        var midY     = h * 50 / 100;
        var valW     = dc.getTextWidthInPixels(valStr, Graphics.FONT_NUMBER_MEDIUM);
        var unitW    = dc.getTextWidthInPixels(unitLbl, Graphics.FONT_MEDIUM);
        var totalW   = valW + 6 + unitW;
        var startX   = valX - totalW / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, midY, Graphics.FONT_NUMBER_MEDIUM, valStr, jL);
        dc.drawText(startX + valW + 6, midY + 4, Graphics.FONT_MEDIUM, unitLbl, jL);
    }
}

// =============================================================================
class GoalPickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as GoalPickerView;

    function initialize(view as GoalPickerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // UP = +шаг
    function onPreviousPage() as Boolean {
        _view.step((DataStore.getUnits() == 0) ? GP_STEP : 8);
        return true;
    }

    // DOWN = -шаг
    function onNextPage() as Boolean {
        _view.step((DataStore.getUnits() == 0) ? -GP_STEP : -8);
        return true;
    }

    // SELECT = установить
    function onSelect() as Boolean {
        DataStore.setGoal(_view.getValue(), true);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var zone   = _view.getZone(coords[0], coords[1]);
        if      (zone == GP_ZONE_MINUS) { _view.step(-GP_STEP); }
        else if (zone == GP_ZONE_PLUS)  { _view.step(GP_STEP); }
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

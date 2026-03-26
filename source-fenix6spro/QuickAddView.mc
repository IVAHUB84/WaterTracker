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

    var addY    as Number = 0;
    var addH    as Number = 0;
    var topZoneH as Number = 0;
    var centerX as Number = 0;

    function initialize() {
        View.initialize();
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
        var minV = isOz ? -68 : QA_MIN;
        var maxV = isOz ?  68 : QA_MAX;
        if (_value < minV) { _value = minV; }
        if (_value > maxV) { _value = maxV; }
        WatchUi.requestUpdate();
    }

    function getZone(tapX as Number, tapY as Number) as Number {
        if (tapY < topZoneH)          { return QA_ZONE_PLUS; }
        if (tapY >= h - topZoneH)     { return QA_ZONE_MINUS; }
        return QA_ZONE_ADD;
    }

    private var h as Number = 0;

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        h         = dc.getHeight();
        centerX   = w / 2;
        topZoneH  = h * 28 / 100;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var jC  = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var jL  = Graphics.TEXT_JUSTIFY_LEFT   | Graphics.TEXT_JUSTIFY_VCENTER;

        // ── Заголовок — белый ────────────────────────────────
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 9 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.TitleCustomAmount) as String, jC);

        // Безопасный отступ от края окружности для каждой строки
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
        var stepLbl = (units2 == 0) ? QA_STEP.toString() : "2";
        dc.setColor(0x1F618D, Graphics.COLOR_TRANSPARENT);
        dc.drawText(upSafeX, upY, Graphics.FONT_MEDIUM, "+" + stepLbl, jL);

        // ── -шаг слева напротив кнопки DOWN ──────────────────
        dc.setColor(0xB71C1C, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dnSafeX, downY, Graphics.FONT_MEDIUM, "-" + stepLbl, jL);

        // ── Добавить — справа напротив кнопки SELECT ─────────
        dc.setColor(0x5A9E6F, Graphics.COLOR_TRANSPARENT);
        dc.drawText(adSafeRX, addLY, Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.BtnAdd) as String,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Счётчик правее центра, крупный ───────────────────
        var units   = DataStore.getUnits();
        var unitLbl = (units == 0)
            ? (WatchUi.loadResource(Rez.Strings.UnitMl) as String)
            : (WatchUi.loadResource(Rez.Strings.UnitOz) as String);
        var valStr  = _value.toString();
        var valColor = _value < 0 ? 0xD50000 : Graphics.COLOR_WHITE;
        var valX     = w * 63 / 100;
        var midY     = h * 50 / 100;
        var valW     = dc.getTextWidthInPixels(valStr, Graphics.FONT_NUMBER_MEDIUM);
        var unitW    = dc.getTextWidthInPixels(unitLbl, Graphics.FONT_LARGE);
        var totalW   = valW + 6 + unitW;
        var startX   = valX - totalW / 2;
        dc.setColor(valColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, midY, Graphics.FONT_NUMBER_MEDIUM, valStr, jL);
        dc.drawText(startX + valW + 6, midY + 4, Graphics.FONT_MEDIUM, unitLbl, jL);
    }
}

// =============================================================================
class QuickAddDelegate extends WatchUi.BehaviorDelegate {

    private var _view as QuickAddView;

    function initialize(view as QuickAddView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // UP = +шаг
    function onPreviousPage() as Boolean {
        _view.step((DataStore.getUnits() == 0) ? QA_STEP : 2);
        return true;
    }

    // DOWN = -шаг
    function onNextPage() as Boolean {
        _view.step((DataStore.getUnits() == 0) ? -QA_STEP : -2);
        return true;
    }

    // SELECT = добавить
    function onSelect() as Boolean {
        DataStore.addAmount(_view.getValue());
        updateComplications();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
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
        // Долгое нажатие по центру = добавить (на touch)
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

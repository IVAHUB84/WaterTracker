// QuickAddView.mc — экран ручного ввода объёма шагом 50 мл
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const QA_STEP    as Number = 50;
const QA_MIN     as Number = 50;
const QA_MAX     as Number = 2000;
const QA_DEFAULT as Number = 200;

// Зоны тапа внутри QuickAdd
const QA_ZONE_NONE  as Number = -1;
const QA_ZONE_MINUS as Number = 0;  // левая часть верхней зоны
const QA_ZONE_PLUS  as Number = 1;  // правая часть верхней зоны
const QA_ZONE_ADD   as Number = 2;  // кнопка Add внизу

function pushQuickAddView() as Void {
    var view = new QuickAddView();
    WatchUi.pushView(view, new QuickAddDelegate(view), WatchUi.SLIDE_UP);
}

// =============================================================================
class QuickAddView extends WatchUi.View {

    private var _value as Number = QA_DEFAULT;

    // Границы зон — заполняются в onUpdate
    var btnSplitY  as Number = 0;  // Y-граница между +/- кнопками и Add
    var btnAddY    as Number = 0;  // верхний край кнопки Add
    var centerX    as Number = 0;

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
        if (tapY >= btnAddY) { return QA_ZONE_ADD; }
        if (tapY >= btnSplitY) {
            return (tapX < centerX) ? QA_ZONE_MINUS : QA_ZONE_PLUS;
        }
        return QA_ZONE_NONE;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        centerX   = w / 2;
        btnSplitY = h * 40 / 100;
        btnAddY   = h * 72 / 100;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Заголовок ────────────────────────────────────────
        dc.setColor(0x777777, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 10 / 100, Graphics.FONT_XTINY,
            "Custom amount",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Текущее значение ─────────────────────────────────
        var units   = DataStore.getUnits();
        var unitLbl = (units == 0) ? " ml" : " oz";
        var valStr  = (units == 0)
            ? _value.toString()
            : (_value.toFloat() / 29.5735f).format("%.0f");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 27 / 100, Graphics.FONT_MEDIUM,
            valStr + unitLbl,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Кнопки −50 / +50 (pill-shape) ────────────────────
        var btnH  = h * 25 / 100;
        var btnR  = btnH / 2;          // радиус = полная таблетка
        var gap   = w * 4 / 100;       // зазор между кнопками
        var margin = w * 6 / 100;      // отступ от края
        var btnW  = (w - 2 * margin - gap) / 2;
        var leftX = margin;
        var rightX = margin + btnW + gap;

        dc.setColor(0x7B241C, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(leftX, btnSplitY, btnW, btnH, btnR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX + btnW / 2, btnSplitY + btnH / 2, Graphics.FONT_SMALL,
            "-50",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x1F618D, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(rightX, btnSplitY, btnW, btnH, btnR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX + btnW / 2, btnSplitY + btnH / 2, Graphics.FONT_SMALL,
            "+50",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Кнопка Add (широкая таблетка) ────────────────────
        var addH  = h * 20 / 100;
        var addR  = addH / 2;
        var addX  = w * 18 / 100;
        var addW  = w * 64 / 100;
        dc.setColor(0x1E8449, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(addX, btnAddY, addW, addH, addR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, btnAddY + addH / 2, Graphics.FONT_SMALL,
            "Add",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

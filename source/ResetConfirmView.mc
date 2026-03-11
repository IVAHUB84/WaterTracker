// ResetConfirmView.mc — экран подтверждения сброса с кнопками Yes / No
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const RC_ZONE_NONE as Number = -1;
const RC_ZONE_NO   as Number = 0;
const RC_ZONE_YES  as Number = 1;

function pushResetConfirm() as Void {
    var view = new ResetConfirmView();
    WatchUi.pushView(view, new ResetConfirmDelegate(view), WatchUi.SLIDE_UP);
}

// =============================================================================
class ResetConfirmView extends WatchUi.View {

    var btnY      as Number = 0;
    var btnH      as Number = 0;
    var centerX   as Number = 0;

    function initialize() {
        View.initialize();
    }

    function getZone(tapX as Number, tapY as Number) as Number {
        if (tapY < btnY || tapY > btnY + btnH) { return RC_ZONE_NONE; }
        return (tapX < centerX) ? RC_ZONE_NO : RC_ZONE_YES;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        centerX = w / 2;
        btnY    = h * 50 / 100;
        btnH    = h * 25 / 100;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Иконка / вопрос ──────────────────────────────────
        dc.setColor(0x777777, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 18 / 100, Graphics.FONT_XTINY,
            "Reset today's water?",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 35 / 100, Graphics.FONT_MEDIUM,
            "0 ml",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Кнопки No / Yes (pill-shape) ─────────────────────
        var btnR   = btnH / 2;
        var gap    = w * 4 / 100;
        var margin = w * 6 / 100;
        var btnW   = (w - 2 * margin - gap) / 2;
        var leftX  = margin;
        var rightX = margin + btnW + gap;

        // No — серо-красный
        dc.setColor(0x7B241C, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(leftX, btnY, btnW, btnH, btnR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX + btnW / 2, btnY + btnH / 2, Graphics.FONT_SMALL,
            "No",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Yes — зелёный
        dc.setColor(0x1E8449, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(rightX, btnY, btnW, btnH, btnR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX + btnW / 2, btnY + btnH / 2, Graphics.FONT_SMALL,
            "Yes",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// =============================================================================
class ResetConfirmDelegate extends WatchUi.BehaviorDelegate {

    private var _view as ResetConfirmView;

    function initialize(view as ResetConfirmView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var zone   = _view.getZone(coords[0], coords[1]);
        if (zone == RC_ZONE_YES) {
            DataStore.reset();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

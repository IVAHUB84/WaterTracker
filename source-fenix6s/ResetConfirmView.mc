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
        btnH    = h * 30 / 100;
        btnY    = h * 50 / 100 - btnH / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var jC = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var radius = w / 2;

        // ── Заголовок по центру ───────────────────────────────
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 50 / 100, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.ResetQuestion) as String, jC);

        // ── ДА (SELECT/START) — правый край ~35% высоты ─────────
        var yesY  = h * 35 / 100;
        var yesDy = yesY - h / 2;
        var yesSafeX = radius + Math.sqrt((radius * radius - yesDy * yesDy).toFloat()).toNumber() - 10;
        dc.setColor(0x1E8449, Graphics.COLOR_TRANSPARENT);
        dc.drawText(yesSafeX, yesY, Graphics.FONT_LARGE,
            WatchUi.loadResource(Rez.Strings.BtnYes) as String,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── НЕТ (BACK/SET) — правый край ~72% высоты ────────────
        var noY  = h * 72 / 100;
        var noDy = noY - h / 2;
        var noSafeX = radius + Math.sqrt((radius * radius - noDy * noDy).toFloat()).toNumber() - 10;
        dc.setColor(0xB71C1C, Graphics.COLOR_TRANSPARENT);
        dc.drawText(noSafeX, noY, Graphics.FONT_LARGE,
            WatchUi.loadResource(Rez.Strings.BtnNo) as String,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
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

    // SELECT = Да
    function onSelect() as Boolean {
        DataStore.reset();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    // BACK = Нет
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

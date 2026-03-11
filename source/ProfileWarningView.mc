// ProfileWarningView.mc — информационный экран о неполном профиле
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

function pushProfileWarningView() as Void {
    WatchUi.pushView(new ProfileWarningView(),
                     new ProfileWarningDelegate(),
                     WatchUi.SLIDE_UP);
}

// =============================================================================
class ProfileWarningView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Иконка предупреждения ─────────────────────────────
        var cx = w / 2;
        var iconY = h * 22 / 100;
        var r = h * 8 / 100;
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, iconY, r);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, iconY, Graphics.FONT_SMALL,
            "!",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Текст сообщения ───────────────────────────────────
        var msg = "Fill your profile\nin Garmin Connect\nfor accurate\nhydration goal";
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 60 / 100, Graphics.FONT_XTINY,
            msg,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// =============================================================================
class ProfileWarningDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

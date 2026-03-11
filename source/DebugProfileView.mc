// DebugProfileView.mc — отладочный экран: формула расчёта REC (с прокруткой)
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.UserProfile;
import Toybox.WatchUi;

function pushDebugProfileView() as Void {
    var view = new DebugProfileView();
    WatchUi.pushView(view, new DebugProfileDelegate(view), WatchUi.SLIDE_DOWN);
}

// =============================================================================
class DebugProfileView extends WatchUi.View {

    private var _scrollY as Number = 0;
    private static const LINE as Number = 25;  // высота строки в px
    private static const TOTAL as Number = 230; // общая высота контента

    function initialize() {
        View.initialize();
    }

    function scroll(dy as Number) as Void {
        _scrollY = _scrollY + dy;
        var maxS = TOTAL - 220;
        if (_scrollY < 0)    { _scrollY = 0; }
        if (_scrollY > maxS) { _scrollY = maxS; }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var s  = _scrollY;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Сбор данных ──────────────────────────────────────
        var weightKg   = 0.0;
        var genderMale = false;
        var profileOk  = false;
        var ageStr     = "n/a";
        var heightStr  = "n/a";

        if (Toybox has :UserProfile) {
            var profile = UserProfile.getProfile();
            if (profile != null) {
                var wG = profile.weight;
                if (wG != null) { weightKg = (wG as Number).toFloat() / 1000.0; }

                var hCm = profile.height;
                if (hCm != null) { heightStr = (hCm as Number).toString() + " cm"; }

                var by = profile.birthYear;
                if (by != null) {
                    var yr = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT).year;
                    ageStr = (yr - (by as Number)).toString() + " yr";
                }

                var g = profile.gender;
                if (g == UserProfile.GENDER_MALE)        { genderMale = true;  profileOk = (weightKg > 0); }
                else if (g == UserProfile.GENDER_FEMALE) { genderMale = false; profileOk = (weightKg > 0); }
            }
        }

        var mod = 0; var vig = 0;
        if (Toybox has :ActivityMonitor) {
            var info = ActivityMonitor.getInfo();
            if (info != null) {
                var am = info.activeMinutesDay;
                if (am != null) {
                    mod = (am.moderate != null) ? (am.moderate as Number) : 0;
                    vig = (am.vigorous != null) ? (am.vigorous as Number) : 0;
                }
            }
        }

        // ── Расчёт ───────────────────────────────────────────
        var base        = (weightKg * 33.0).toNumber();
        var genderBonus = genderMale ? 200 : 0;
        var actBonus    = (mod + vig * 2) * 8;
        var recVal      = profileOk ? (base + genderBonus + actBonus) : 2000;
        var baseGoal    = profileOk ? (base + genderBonus) : 2000;
        var genderLbl   = genderMale ? "M" : "F";

        // ── Вспомогательная функция отрисовки строки ─────────
        // Рисует текст только если y попадает в видимую область
        var margin = 18;

        // Заголовок (фиксированный — не прокручивается)
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, margin, Graphics.FONT_XTINY,
            "Formula",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Разделитель под заголовком
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - 60, 32, cx + 60, 32);

        // ── Прокручиваемый контент (начало y=40 в контент-координатах) ──
        var base_y = 40;  // верхняя граница контента

        // ── Профиль пользователя ─────────────────────────────
        _drawLine(dc, cx, base_y + LINE * 0 - s, 0x888888,
            "Weight:  " + weightKg.format("%.1f") + " kg", h);
        _drawLine(dc, cx, base_y + LINE * 1 - s, 0x888888,
            "Height:  " + heightStr, h);
        _drawLine(dc, cx, base_y + LINE * 2 - s, 0x888888,
            "Age:     " + ageStr, h);
        _drawLine(dc, cx, base_y + LINE * 3 - s, 0x888888,
            "Gender:  " + genderLbl, h);
        _drawLine(dc, cx, base_y + LINE * 4 - s, 0x888888,
            "ActMin:  " + mod.toString() + "m + " + vig.toString() + "v", h);

        _drawDivider(dc, cx, base_y + LINE * 5 - 5 - s, h);

        // ── Формулы ──────────────────────────────────────────
        // GOAL base = weight×33 + genderBonus = baseGoal
        var goalLine = "GOAL = " + weightKg.format("%.1f") + "x33+" +
                       genderBonus.toString() + " = " + baseGoal.toString();
        _drawLine(dc, cx, base_y + LINE * 5 + 12 - s, 0x666666, goalLine, h);

        // REC = baseGoal + actBonus = recVal
        var recLine = "REC = " + baseGoal.toString() + "+" +
                      actBonus.toString() + " = " + recVal.toString();
        _drawLine(dc, cx, base_y + LINE * 6 + 12 - s, 0x00AAFF, recLine, h);

        // Скролл-индикатор
        if (_scrollY > 0 || TOTAL - 220 > 0) {
            var trackH = h - 60;
            var trackX = w - 6;
            var trackY = 40;
            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(trackX, trackY, 3, trackH);
            var maxS = TOTAL - 220;
            if (maxS > 0) {
                var thumbH = trackH * 220 / TOTAL;
                var thumbY = trackY + (trackH - thumbH) * _scrollY / maxS;
                dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(trackX, thumbY, 3, thumbH);
            }
        }

        // Подсказка (фиксированная)
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h - 12, Graphics.FONT_XTINY,
            "swipe ^ v  |  tap=close",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _drawLine(dc as Graphics.Dc, cx as Number, y as Number,
                                color as Number, text as String, h as Number) as Void {
        if (y < 34 || y > h - 20) { return; }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _drawDivider(dc as Graphics.Dc, cx as Number,
                                   y as Number, h as Number) as Void {
        if (y < 34 || y > h - 20) { return; }
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - 50, y, cx + 50, y);
    }
}

// =============================================================================
class DebugProfileDelegate extends WatchUi.BehaviorDelegate {

    private var _view    as DebugProfileView;
    private var _lastY   as Number = -1;

    function initialize(view as DebugProfileView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onDrag(evt as WatchUi.DragEvent) as Boolean {
        var y = evt.getCoordinates()[1];
        if (_lastY < 0) { _lastY = y; return true; }
        var dy = _lastY - y;
        if (dy > 8 || dy < -8) {
            _view.scroll(dy);
            _lastY = y;
        }
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP)   { _view.scroll(60); }
        if (dir == WatchUi.SWIPE_DOWN) { _view.scroll(-60); }
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        _lastY = -1;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

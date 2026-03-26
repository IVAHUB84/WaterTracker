// DebugProfileView.mc — отладочный экран: формула расчёта REC (с прокруткой)
import Toybox.ActivityMonitor;
import Toybox.Application;
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
    private static const TOTAL as Number = 280; // общая высота контента

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

        // Дата
        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var mm = today.month as Number;
        var dd = today.day as Number;
        var hr = today.hour as Number;
        var mn = today.min as Number;
        var monthStr = (mm < 10) ? ("0" + mm.toString()) : mm.toString();
        var dayStr   = (dd < 10) ? ("0" + dd.toString()) : dd.toString();
        var hrStr    = (hr < 10) ? ("0" + hr.toString()) : hr.toString();
        var mnStr    = (mn < 10) ? ("0" + mn.toString()) : mn.toString();
        var dateStr  = dayStr + "." + monthStr + "." + today.year.toString();
        var timeStr  = hrStr + ":" + mnStr;

        // Масштаб под любой экран (эталон 260px)
        var sc = h;

        // ── Заголовок ─────────────────────────────────────────
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, sc * 14 / 260, Graphics.FONT_XTINY, "Formula",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, sc * 32 / 260, Graphics.FONT_XTINY, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - 60, sc * 44 / 260, cx + 60, sc * 44 / 260);

        // ── Профиль: два столбца (левый — right-align, правый — left-align) ──
        var jL = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
        var jR = Graphics.TEXT_JUSTIFY_LEFT  | Graphics.TEXT_JUSTIFY_VCENTER;
        var col1x = cx - 8;
        var col2x = cx + 8;
        var row1y = sc * 60  / 260 - s;
        var row2y = sc * 84  / 260 - s;
        dc.setColor(0xE0E0E0, Graphics.COLOR_TRANSPARENT);
        if (row1y > sc * 44 / 260 && row1y < h - 10) {
            dc.drawText(col1x, row1y, Graphics.FONT_XTINY, "Wt: " + weightKg.format("%.1f") + " kg", jL);
            dc.drawText(col2x, row1y, Graphics.FONT_XTINY, "Ht: " + heightStr, jR);
        }
        if (row2y > sc * 44 / 260 && row2y < h - 10) {
            dc.drawText(col1x, row2y, Graphics.FONT_XTINY, "Age: " + ageStr, jL);
            dc.drawText(col2x, row2y, Graphics.FONT_XTINY, "Sex: " + genderLbl, jR);
        }
        _drawLine(dc, cx, sc * 110 / 260 - s, 0xE0E0E0,
            "Act = " + mod.toString() + " mod + " + vig.toString() + " vig", h);
        _drawLine(dc, cx, sc * 126 / 260 - s, 0x546E7A, "moderate + vigorous \u00D72", h);

        // ── Разделитель ──────────────────────────────────────
        var dv = sc * 142 / 260 - s;
        if (dv > sc * 44 / 260 && dv < h - 10) {
            dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(cx - 55, dv, cx + 55, dv);
        }

        // ── Формулы ──────────────────────────────────────────
        var units = DataStore.getUnits();
        var goalDisp = (units == 0) ? baseGoal.toString() : (baseGoal.toFloat() / 29.5735f).format("%.0f");
        var recDisp  = (units == 0) ? recVal.toString()   : (recVal.toFloat()  / 29.5735f).format("%.0f");
        var uLbl = (units == 0) ? "ml" : "oz";
        var goalLine = "GOAL=" + weightKg.format("%.1f") + "x33+" +
                       genderBonus.toString() + "=" + goalDisp + uLbl;
        _drawLine(dc, cx, sc * 162 / 260 - s, 0xFFB300, goalLine, h);
        _drawLine(dc, cx, sc * 178 / 260 - s, 0x546E7A, "base daily norm", h);

        var recLine = "REC=" + goalDisp + "+" +
                      actBonus.toString() + "=" + recDisp + uLbl;
        _drawLine(dc, cx, sc * 204 / 260 - s, 0x29B6F6, recLine, h);
        _drawLine(dc, cx, sc * 220 / 260 - s, 0x546E7A, "base + ActivityScore", h);

        // ── Время обновления ──────────────────────────────────
        var dv2 = sc * 236 / 260 - s;
        if (dv2 > sc * 44 / 260 && dv2 < h - 10) {
            dc.setColor(0x2A2A2A, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(cx - 55, dv2, cx + 55, dv2);
        }
        _drawLine(dc, cx, sc * 248 / 260 - s, 0x3A3A3A, "Activity updated " + timeStr, h);

        // ── Статус Complications ──────────────────────────────
        var cmpStat = Application.Storage.getValue("_cmpStat");
        var cmpStr  = "CMP: " + ((cmpStat != null) ? cmpStat.toString() : "—");
        _drawLine(dc, cx, sc * 268 / 260 - s, 0x1565C0, cmpStr, h);

    }

    private function _drawLine(dc as Graphics.Dc, cx as Number, y as Number,
                                color as Number, text as String, h as Number) as Void {
        if (y < 34 || y > h - 20) { return; }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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

    function onPreviousPage() as Boolean {
        _view.scroll(-60);
        return true;
    }

    function onNextPage() as Boolean {
        _view.scroll(60);
        return true;
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

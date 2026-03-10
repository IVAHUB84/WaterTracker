// WaterTrackerView.mc — главный экран
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class WaterTrackerView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        var amount  = DataStore.getAmount();
        var goal    = DataStore.getGoal();
        var units   = DataStore.getUnits();
        var percent = (goal > 0)
            ? ((amount * 100 / goal) > 100 ? 100 : amount * 100 / goal)
            : 0;
        var reached = (amount >= goal);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Круговой прогресс-бар (кольцо)
        _drawArcProgress(dc, cx, cy, w, percent, reached);

        // Объём — крупно в центре
        var amountStr = _fmt(amount, units);
        dc.setColor(
            reached ? Graphics.COLOR_GREEN : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.drawText(
            cx, cy - h * 6 / 100,
            Graphics.FONT_NUMBER_MEDIUM,
            amountStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Единица + цель
        var unitLabel = (units == 0) ? "ml" : "oz";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, cy + h * 9 / 100,
            Graphics.FONT_TINY,
            "/ " + _fmt(goal, units) + " " + unitLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Процент или "Цель достигнута"
        if (reached) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                cx, cy + h * 22 / 100,
                Graphics.FONT_TINY,
                WatchUi.loadResource(Rez.Strings.LabelGoalReached) as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            dc.setColor(0x0088FF, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                cx, cy + h * 22 / 100,
                Graphics.FONT_SMALL,
                percent.toString() + "%",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // Время последнего приёма
        _drawLastTime(dc, cx, h);
    }

    // -------------------------------------------------------------------------

    // Круговое кольцо прогресса (gap внизу, заполняется по часовой начиная с 7:30)
    private function _drawArcProgress(
        dc      as Graphics.Dc,
        cx      as Number,
        cy      as Number,
        w       as Number,
        percent as Number,
        reached as Boolean
    ) as Void {
        var r    = w * 43 / 100;
        var penW = 14;
        dc.setPenWidth(penW);

        // Фоновая дуга: тёмно-серая, 270° от 315° до 225° (CCW через верх)
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 315, 225);

        // Дуга прогресса: заполняется от 7:30 (225°) по часовой стрелке
        if (percent > 0) {
            var sweep  = percent * 270 / 100;
            var endPt  = ((225 - sweep) + 360) % 360;
            dc.setColor(
                reached ? Graphics.COLOR_GREEN : 0x0077FF,
                Graphics.COLOR_TRANSPARENT
            );
            dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, endPt, 225);
        }

        dc.setPenWidth(1);
    }

    private function _drawLastTime(dc as Graphics.Dc, cx as Number, h as Number) as Void {
        var lastTs  = DataStore.getLastTime();
        var timeStr = WatchUi.loadResource(Rez.Strings.LabelNever) as String;

        if (lastTs != null) {
            var info = Gregorian.info(new Time.Moment(lastTs as Number), Time.FORMAT_SHORT);
            timeStr = (info.hour as Number).format("%02d") + ":" +
                      (info.min  as Number).format("%02d");
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx, h * 90 / 100,
            Graphics.FONT_TINY,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function _fmt(ml as Number, units as Number) as String {
        if (units == 0) { return ml.toString(); }
        return (ml.toFloat() / 29.5735f).format("%.1f");
    }
}

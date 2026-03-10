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
        // Макет задаётся через onUpdate (программная отрисовка)
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var amount  = DataStore.getAmount();
        var goal    = DataStore.getGoal();
        var percent = DataStore.getPercent();
        var units   = DataStore.getUnits(); // 0 = мл, 1 = oz

        var w = dc.getWidth();
        var h = dc.getHeight();

        // Фон
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // --- Прогресс-бар ---
        _drawProgressBar(dc, w, h, percent);

        // --- Объём: выпито / цель ---
        var amountDisplay = _formatAmount(amount, units);
        var goalDisplay   = _formatAmount(goal, units);
        var unitLabel     = (units == 0) ? "ml" : "oz";

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 35 / 100,
            Graphics.FONT_NUMBER_MEDIUM,
            amountDisplay,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 50 / 100,
            Graphics.FONT_TINY,
            "/ " + goalDisplay + " " + unitLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Процент ---
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 65 / 100,
            Graphics.FONT_SMALL,
            percent.toString() + "%",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // --- Время последнего приёма ---
        _drawLastTime(dc, w, h);
    }

    // Прогресс-бар (горизонтальная полоса внизу)
    private function _drawProgressBar(dc as Graphics.Dc, w as Number, h as Number, percent as Number) as Void {
        var barY      = h * 82 / 100;
        var barH      = 8;
        var barPadX   = 20;
        var barW      = w - barPadX * 2;
        var fillW     = (barW * percent) / 100;

        // Фон полосы
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barPadX, barY, barW, barH, 4);

        // Заполнение
        if (fillW > 0) {
            var color = (percent >= 100)
                ? Graphics.COLOR_GREEN
                : Graphics.COLOR_BLUE;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barPadX, barY, fillW, barH, 4);
        }
    }

    // Время последнего стакана воды
    private function _drawLastTime(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var lastTs = DataStore.getLastTime();
        var timeStr;

        if (lastTs == null) {
            timeStr = WatchUi.loadResource(Rez.Strings.LabelNever) as String;
        } else {
            var info = Gregorian.info(new Time.Moment(lastTs), Time.FORMAT_SHORT);
            var hh = info.hour.format("%02d");
            var mm = info.min.format("%02d");
            timeStr = hh + ":" + mm;
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 91 / 100,
            Graphics.FONT_TINY,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // Форматировать объём: мл или oz
    private function _formatAmount(ml as Number, units as Number) as String {
        if (units == 0) {
            return ml.toString();
        }
        // 1 oz ≈ 29.574 мл
        var oz = (ml * 10 / 296).toFloat() / 10.0;
        return oz.format("%.1f");
    }
}

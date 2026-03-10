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

    // Вызывается при возврате на этот экран (после popView)
    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Читаем все данные за один проход — одна проверка даты
        var amount  = DataStore.getAmount();
        var goal    = DataStore.getGoal();
        var units   = DataStore.getUnits();
        var percent = (goal > 0)
            ? ((amount * 100 / goal) > 100 ? 100 : amount * 100 / goal)
            : 0;
        var reached = (amount >= goal);

        // Фон
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Прогресс-бар
        _drawProgressBar(dc, w, h, percent, reached);

        // Объём (большой шрифт)
        var amountStr = _formatAmount(amount, units);
        dc.setColor(
            reached ? Graphics.COLOR_GREEN : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.drawText(
            w / 2, h * 33 / 100,
            Graphics.FONT_NUMBER_MEDIUM,
            amountStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // "/ цель единица"
        var unitLabel  = (units == 0) ? "ml" : "oz";
        var goalStr    = _formatAmount(goal, units);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 50 / 100,
            Graphics.FONT_TINY,
            "/ " + goalStr + " " + unitLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Процент или "Цель достигнута!"
        if (reached) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                w / 2, h * 63 / 100,
                Graphics.FONT_TINY,
                WatchUi.loadResource(Rez.Strings.LabelGoalReached) as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                w / 2, h * 63 / 100,
                Graphics.FONT_SMALL,
                percent.toString() + "%",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // Время последнего приёма
        _drawLastTime(dc, w, h);
    }

    // -------------------------------------------------------------------------
    // Приватные методы

    private function _drawProgressBar(
        dc      as Graphics.Dc,
        w       as Number,
        h       as Number,
        percent as Number,
        reached as Boolean
    ) as Void {
        var barY    = h * 80 / 100;
        var barH    = 10;
        var padX    = 20;
        var barW    = w - padX * 2;
        var fillW   = (barW * percent) / 100;

        // Фон полосы
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(padX, barY, barW, barH, 5);

        // Заполнение
        if (fillW > 0) {
            dc.setColor(
                reached ? Graphics.COLOR_GREEN : Graphics.COLOR_BLUE,
                Graphics.COLOR_TRANSPARENT
            );
            dc.fillRoundedRectangle(padX, barY, fillW, barH, 5);
        }
    }

    private function _drawLastTime(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var lastTs  = DataStore.getLastTime();
        var timeStr = WatchUi.loadResource(Rez.Strings.LabelNever) as String;

        if (lastTs != null) {
            var info = Gregorian.info(new Time.Moment(lastTs as Number), Time.FORMAT_SHORT);
            timeStr = (info.hour as Number).format("%02d") + ":" +
                      (info.min  as Number).format("%02d");
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 91 / 100,
            Graphics.FONT_TINY,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // мл → строка в выбранных единицах
    private function _formatAmount(ml as Number, units as Number) as String {
        if (units == 0) {
            return ml.toString();
        }
        // 1 fl oz = 29.5735 мл
        return (ml.toFloat() / 29.5735f).format("%.1f");
    }
}

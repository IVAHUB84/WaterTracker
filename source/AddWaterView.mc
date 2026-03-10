// AddWaterView.mc — экран добавления воды + подтверждение
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// =============================================================================
// Экран выбора порции (3 кнопки)

class AddWaterView extends WatchUi.View {

    private static const PORTIONS as Array<Number> = [150, 250, 350];
    private var _selected as Number = 1; // средняя кнопка по умолчанию

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w     = dc.getWidth();
        var h     = dc.getHeight();
        var units = DataStore.getUnits();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Заголовок
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 12 / 100,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.TitleAddWater) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Кнопки
        var btnH   = h * 20 / 100;
        var btnW   = w * 72 / 100;
        var btnX   = (w - btnW) / 2;
        var startY = h * 23 / 100;
        var gapY   = h * 25 / 100;

        for (var i = 0; i < 3; i++) {
            var isActive = (i == _selected);
            var btnY     = startY + i * gapY;

            dc.setColor(
                isActive ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GRAY,
                Graphics.COLOR_TRANSPARENT
            );
            dc.fillRoundedRectangle(btnX, btnY, btnW, btnH, 8);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                w / 2, btnY + btnH / 2,
                Graphics.FONT_SMALL,
                _portionLabel(PORTIONS[i], units),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    function selectNext() as Void {
        _selected = (_selected + 1) % 3;
        WatchUi.requestUpdate();
    }

    function selectPrev() as Void {
        _selected = (_selected + 2) % 3;
        WatchUi.requestUpdate();
    }

    function getPortionMl() as Number {
        return PORTIONS[_selected];
    }

    private function _portionLabel(ml as Number, units as Number) as String {
        if (units == 0) {
            return "+" + ml.toString() + " ml";
        }
        return "+" + (ml.toFloat() / 29.5735f).format("%.1f") + " oz";
    }
}

// =============================================================================
// Делегат экрана выбора порции

class AddWaterDelegate extends WatchUi.BehaviorDelegate {

    private var _view      as AddWaterView;
    private var _confirmed as Boolean = false;

    // view передаётся снаружи при pushView
    function initialize(view as AddWaterView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // SELECT — записать и показать подтверждение
    function onSelect() as Boolean {
        if (_confirmed) { return true; }
        _confirmed = true;

        var ml        = _view.getPortionMl();
        var newAmount = DataStore.addAmount(ml);

        var confirmView = new ConfirmView(ml, newAmount);
        WatchUi.pushView(
            confirmView,
            new ConfirmDelegate(confirmView),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    // DOWN — следующая кнопка
    function onNextPage() as Boolean {
        _view.selectNext();
        return true;
    }

    // UP — предыдущая кнопка
    function onPreviousPage() as Boolean {
        _view.selectPrev();
        return true;
    }

    // BACK — вернуться на главный без записи
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// =============================================================================
// Экран подтверждения добавления

class ConfirmView extends WatchUi.View {

    private var _addedMl as Number;
    private var _totalMl as Number;

    function initialize(added as Number, total as Number) {
        View.initialize();
        _addedMl = added;
        _totalMl = total;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w     = dc.getWidth();
        var h     = dc.getHeight();
        var units = DataStore.getUnits();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Большая галочка
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 30 / 100,
            Graphics.FONT_NUMBER_MEDIUM,
            "\u2713", // ✓
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Добавленный объём
        var unitStr = (units == 0) ? " ml" : " oz";
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 54 / 100,
            Graphics.FONT_MEDIUM,
            "+" + _fmt(_addedMl, units) + unitStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Итог / цель
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 72 / 100,
            Graphics.FONT_TINY,
            _fmt(_totalMl, units) + " / " +
            _fmt(DataStore.getGoal(), units) + unitStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function _fmt(ml as Number, units as Number) as String {
        if (units == 0) { return ml.toString(); }
        return (ml.toFloat() / 29.5735f).format("%.1f");
    }
}

// =============================================================================
// Делегат экрана подтверждения (авто-возврат через 2 сек)

class ConfirmDelegate extends WatchUi.BehaviorDelegate {

    private var _timer as Timer.Timer;
    private var _view  as ConfirmView;

    function initialize(view as ConfirmView) {
        BehaviorDelegate.initialize();
        _view  = view;
        _timer = new Timer.Timer();
        // Авто-возврат через 2000 мс
        _timer.start(method(:onTimeout), 2000, false);
    }

    // Таймер сработал — вернуться на главный экран
    function onTimeout() as Void {
        _popToMain();
    }

    // BACK — остановить таймер и вернуться вручную
    function onBack() as Boolean {
        _timer.stop();
        _popToMain();
        return true;
    }

    // Снять ConfirmView + AddWaterView, вернуться на главный экран
    private function _popToMain() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN); // ConfirmView → AddWaterView
        WatchUi.popView(WatchUi.SLIDE_DOWN); // AddWaterView → MainView
    }
}
